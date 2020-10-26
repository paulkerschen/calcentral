module Oec
  module MergedSheetValidation

    include Validator

    def build_and_validate_export_sheets
      course_confirmations_file = @remote_drive.find_nested [@term_code, Oec::Folder.merged_confirmations, 'Merged course confirmations'], on_failure: :error
      course_confirmations = Oec::SisImportSheet.from_csv(@remote_drive.export_csv(course_confirmations_file), dept_code: nil, term_code: @term_code)

      supervisor_confirmations_file = @remote_drive.find_nested [@term_code, Oec::Folder.merged_confirmations, 'Merged supervisor confirmations'], on_failure: :error
      supervisor_confirmations = Oec::Supervisors.from_csv @remote_drive.export_csv(supervisor_confirmations_file)

      instructors = Oec::Instructors.new
      course_instructors = Oec::CourseInstructors.new
      courses = Oec::Courses.new
      students = Oec::Students.new
      course_students = Oec::CourseStudents.new
      supervisors = Oec::Supervisors.new
      department_hierarchy = Oec::DepartmentHierarchy.new
      report_viewer_hierarchy = Oec::ReportViewerHierarchy.new

      if (previous_course_supervisors = @remote_drive.find_nested [@term_code, Oec::Folder.overrides, 'course_supervisors'])
        course_supervisors = Oec::CourseSupervisors.from_csv @remote_drive.export_csv(previous_course_supervisors)
      else
        course_supervisors = Oec::CourseSupervisors.new
      end

      # Carry over course-instructor associations from previous years, and note instructor UIDs to fill
      # any gaps in the this term's instructor data.
      previous_instructor_uids = Set.new
      if (previous_term_folder = find_previous_term_folder) && (previous_term_last_export = find_last_export previous_term_folder)
        previous_course_instructors = worksheet_from_folder(previous_term_last_export, Oec::CourseInstructors)
        previous_instructors = worksheet_from_folder(previous_term_last_export, Oec::Instructors)
        if previous_course_instructors && previous_instructors
          previous_course_instructors.each do |row|
            validate_and_add(course_instructors, row, %w(LDAP_UID COURSE_ID))
            previous_instructor_uids << row['LDAP_UID']
          end
        end
      end

      ccns = Set.new
      suffixed_ccns = {}

      default_dates = default_term_dates
      participating_dept_names = Oec::DepartmentMappings.new(term_code: @term_code).participating_dept_names
      participating_dept_forms = participating_dept_names.collect {|d| Oec::Worksheet.dept_form_from_name d}

      log :info, "Validating #{supervisor_confirmations.count} supervisor confirmation rows"
      add_from_supervisor_confirmations(supervisor_confirmations, supervisors, department_hierarchy, report_viewer_hierarchy)

      log :info, "Validating #{course_confirmations.count} course confirmation rows"
      course_confirmations.each do |confirmation|
        next unless confirmation['EVALUATE'] && confirmation['EVALUATE'].casecmp('Y') == 0

        validate('courses', confirmation['COURSE_ID']) do |errors|
          errors.add('Blank instructor LDAP_UID') && next if confirmation['LDAP_UID'].blank?
          errors.add("Incorrect term code in COURSE_ID #{confirmation['COURSE_ID']}") && next unless confirmation['COURSE_ID'].start_with?(@term_code)
          if default_dates
            course_dates = confirmation.slice('START_DATE', 'END_DATE')
            if confirmation['MODULAR_COURSE'].blank?
              errors.add "Unexpected dates #{confirmation['START_DATE']} to #{confirmation['END_DATE']} for non-modular course" unless course_dates == default_dates
            elsif confirmation['MODULAR_COURSE'] == 'Y'
              errors.add "Default term dates #{confirmation['START_DATE']} to #{confirmation['END_DATE']} for modular course" if course_dates == default_dates
            end
            errors.add "START_DATE #{confirmation['START_DATE']} does not match term code #{@term_code}" unless confirmation['START_DATE'].end_with? @term_code[0..3]
            errors.add "END_DATE #{confirmation['END_DATE']} does not match term code #{@term_code}" unless confirmation['END_DATE'].end_with? @term_code[0..3]
          end
          errors.add "Unexpected MODULAR_COURSE value #{confirmation['MODULAR_COURSE']}" unless confirmation['MODULAR_COURSE'].blank? || confirmation['MODULAR_COURSE'] == 'Y'
          course_row = confirmation.to_h
          if confirmation['DEPT_FORM'].present? && confirmation['EVALUATION_TYPE'].present?
            course_row['QB_MAPPING'] = "#{confirmation['DEPT_FORM']}-#{confirmation['EVALUATION_TYPE']}"
          end
          validate_and_add(courses, course_row, %w(COURSE_ID))
        end

        if confirmation['LDAP_UID'].present?
          validate_and_add(instructors, confirmation, %w(LDAP_UID))
          validate_and_add(course_instructors, confirmation, %w(LDAP_UID COURSE_ID))
        end

        if confirmation['DEPT_FORM'].present?
          dept_supervisors = supervisors.matching_dept_form(confirmation['DEPT_FORM'])
          validate('courses', confirmation['COURSE_ID']) do |errors|
            log :warn, "DEPT_FORM #{confirmation['DEPT_FORM']} not found among participating departments" unless participating_dept_forms.include? confirmation['DEPT_FORM']
            report_eval_type = "#{confirmation['EVALUATION_TYPE']} in course #{confirmation['COURSE_ID']}"
            case confirmation['DEPT_FORM']
              when 'LAW'
                log :warn, "Unexpected evaluation type for LAW department form: #{report_eval_type}" unless confirmation['EVALUATION_TYPE'].in? %w(1 1A 2 2A 3 3A 4 4A)
              when 'SPANISH'
                log :warn, "Unexpected evaluation type for SPANISH department form: #{report_eval_type}" unless confirmation['EVALUATION_TYPE'].in? %w(LANG LECT SEMI WRIT)
              else
                log :warn, "Unexpected evaluation type: #{report_eval_type}" unless confirmation['EVALUATION_TYPE'].in? %w(F G)
            end
            errors.add "No supervisors found for DEPT_FORM #{confirmation['DEPT_FORM']}" if dept_supervisors.none?
            dept_supervisors.each do |supervisor|
              course_supervisor_row = {
                'COURSE_ID' => confirmation['COURSE_ID'],
                'LDAP_UID' => supervisor['LDAP_UID'],
                'DEPT_NAME' => confirmation['DEPT_FORM']
              }
              validate_and_add(course_supervisors, course_supervisor_row, %w(LDAP_UID COURSE_ID))
            end
          end
        end

        next unless (ccn = confirmation['COURSE_ID'].split('-')[2])
        ccn, suffix = ccn.split('_')
        if suffix
          suffixed_ccns[ccn] ||= Set.new
          suffixed_ccns[ccn] << suffix
        else
          ccns << ccn
        end
      end

      # To avoid conflicts with current-term instructor data, go back and fill in data for previous instructors
      # only after current instructors have been added.
      previous_instructors.try(:each) do |row|
        if previous_instructor_uids.include?(row['LDAP_UID']) && instructors[row['LDAP_UID']].nil?
          validate_and_add(instructors, row, %w(LDAP_UID))
        end
      end

      courses.group_by { |course| course['CROSS_LISTED_NAME'] }.each do |cross_listed_name, courses|
        next if cross_listed_name.blank?
        course_ids = courses.map { |course| course['COURSE_ID'] }
        comparison_course_id = course_ids.shift
        expected_instructor_ids = course_instructors.uids_for_course_id(comparison_course_id).sort
        course_ids.each do |course_id|
          validate('courses', course_id) do |errors|
            instructor_ids = course_instructors.uids_for_course_id(course_id).sort
            if instructor_ids != expected_instructor_ids
              log :warn, "Instructor list (#{instructor_ids.join ', '}) differs from instructor list (#{expected_instructor_ids.join ', '}) of cross-listed course #{comparison_course_id}"
            end
          end
        end
      end

      log :warn, "Retrieving enrollment data for the #{@term_code} term. This will take a few minutes...."
      evaluated_section_ids = ccns + suffixed_ccns.keys
      enrollments = Oec::Queries.get_enrollments(@term_code, evaluated_section_ids)
      log :warn, "Enrollment data retrieved. Validating enrollments for #{evaluated_section_ids.length} evaluated sections."

      enrollments[:rows].each do |enrollment_row|
        row = EdoOracle::Adapters::Oec.adapt_enrollment_row(enrollment_row, enrollments[:columns], @term_code)

        if ccns.include? row['SECTION_ID']
          validate_and_add(students, row, %w(LDAP_UID))
          validate_and_add(course_students, row, %w(LDAP_UID COURSE_ID))
        end

        if suffixed_ccns.has_key? row['SECTION_ID']
          validate_and_add(students, row, %w(LDAP_UID))

          # Course IDs with suffixes need those suffixes re-appended to Oracle results.
          suffixed_ccns[row['SECTION_ID']].each do |suffix|
            row_copy = row.dup
            row_copy['COURSE_ID'] = "#{row['COURSE_ID']}_#{suffix}"
            validate_and_add(course_students, row_copy, %w(LDAP_UID COURSE_ID))
          end
        end
      end

      validate_integrity('LDAP_UID', students, course_students)
      validate_integrity('LDAP_UID', instructors, course_instructors)

      # Course_instructors may include pairings from previous terms; only current-term pairings should be validated against courses.
      validate_integrity('COURSE_ID', courses, course_instructors) do |id|
        id.start_with? @term_code
      end

      if valid?
        log :info, 'Validation passed.'
        [instructors, course_instructors, courses, students, course_students, supervisors, course_supervisors, department_hierarchy, report_viewer_hierarchy]
      else
        @status = 'Error'
        log :warn, 'Validation failed!'
        log_validation_errors
        nil
      end
    end

    def add_from_supervisor_confirmations(supervisor_confirmations, supervisors, department_hierarchy, report_viewer_hierarchy)
      dept_keys = %w(DEPT_NAME_1 DEPT_NAME_2 DEPT_NAME_3 DEPT_NAME_4 DEPT_NAME_5 DEPT_NAME_6 DEPT_NAME_7 DEPT_NAME_8 DEPT_NAME_9 DEPT_NAME_10)
      validate_and_add(department_hierarchy, department_hierarchy.university_row(), ['NODE_ID'])
      supervisor_confirmations.each do |confirmation|
        validate_and_add(supervisors, confirmation, %w(LDAP_UID))
        depts = confirmation.slice(*dept_keys).values.compact
        depts.each do |dept|
          viewer_row = {
            'SOURCE' => dept,
            'TARGET' => confirmation['LDAP_UID'],
            'ROLE_ID' => confirmation['SUPERVISOR_GROUP'],
          }
          validate_and_add(report_viewer_hierarchy, viewer_row, %w(SOURCE TARGET))
          validate_and_add(department_hierarchy, department_hierarchy.department_row(dept), %w(NODE_ID))
        end
      end

    end

    def validate_integrity(key, *worksheets)
      id_sets = worksheets.map do |worksheet|
        ids = Set.new
        worksheet.each do |row|
          # Provide an optional block to select a subset of IDs for validation.
          ids.add(row[key]) if (!block_given? || yield(row[key]))
        end
        {
          name: worksheet.class.export_name,
          ids: ids
        }
      end
      id_sets.permutation do |set1, set2|
        (set1[:ids] - set2[:ids]).each do |id|
          validate(set1[:name], key) { |errors| errors.add "#{key} #{id} found in #{set1[:name]} but not #{set2[:name]}" }
        end
      end
    end

    def worksheet_from_folder(folder, klass)
      if (file = find_csv_in_folder(folder, "#{klass.export_name}.csv")) && (file.mime_type == 'text/csv')
        klass.from_csv @remote_drive.download_string(file)
      end
    end

  end
end
