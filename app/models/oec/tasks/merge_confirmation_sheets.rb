module Oec
  module Tasks
    class MergeConfirmationSheets < Base

      include Oec::Validator

      def run_internal
        term_folder = @remote_drive.find_first_matching_item @term_code
        imports_folder = @remote_drive.find_first_matching_item(Oec::Folder.sis_imports, term_folder)
        most_recent_import = @remote_drive.find_folders(imports_folder.id).sort_by(&:name).last
        raise UnexpectedDataError, "No SIS imports found for term #{@term_code}" unless most_recent_import

        confirmations_folder = @remote_drive.find_first_matching_item(Oec::Folder.confirmations, term_folder)
        raise UnexpectedDataError, "No '#{Oec::Folder.confirmations}' folder found for term #{@term_code}" unless confirmations_folder
        merged_confirmations_folder = @remote_drive.find_first_matching_item(Oec::Folder.merged_confirmations, term_folder)
        raise UnexpectedDataError, "No '#{Oec::Folder.merged_confirmations}' folder found for term #{@term_code}" unless merged_confirmations_folder

        merged_course_confirmations = Oec::Worksheets::SisImport.new(export_name: 'Merged course confirmations', term_code: @term_code)

        department_names = Oec::DepartmentMappings.new(term_code: @term_code).by_dept_code(@departments_filter).keys.map { |code| Berkeley::Departments.get(code, concise: true) }
        @term_dates = default_term_dates

        course_confirmation_worksheets = []

        @remote_drive.get_items_in_folder(confirmations_folder.id).each do |department_item|
          next unless department_names.include? department_item.name

          if (sis_import_sheet = @remote_drive.find_first_matching_item(department_item.name, most_recent_import))
            sis_import = Oec::Worksheets::SisImport.from_csv(@remote_drive.export_csv(sis_import_sheet), term_code: @term_code)
          else
            raise UnexpectedDataError, "Could not find sheet '#{department_item.name}' in folder '#{most_recent_import.name}'"
          end

          confirmation_sheet = @remote_drive.spreadsheet_by_id department_item.id

          if (course_confirmation_worksheet = confirmation_sheet.worksheets.find { |w| w.title == 'Courses' })
            course_confirmation_worksheets << course_confirmation_worksheet
            course_confirmation = Oec::Worksheets::CourseConfirmation.from_csv @remote_drive.export_csv(course_confirmation_worksheet)
            log :info, "Retrieved course confirmations from department sheet '#{department_item.name}'"
          else
            raise UnexpectedDataError, "Could not find worksheet 'Courses' in sheet '#{confirmation_sheet.name}'"
          end

          merged_course_rows = []
          course_confirmation.each do |course_confirmation_row|
            validate('Merged course confirmations', "#{course_confirmation_row['COURSE_ID']}-#{course_confirmation_row['LDAP_UID']}") do |errors|
              sis_import_rows = sis_import.select { |row| row['LDAP_UID'] == course_confirmation_row['LDAP_UID'] && row['COURSE_ID'] == course_confirmation_row['COURSE_ID']  }
              if sis_import_rows.none?
                errors.add 'No SIS import row found matching confirmation row'
                inferred_sis_row = infer_sis_values(course_confirmation_row)
                merged_course_rows << Oec::Worksheets::Row.new(inferred_sis_row, merged_course_confirmations).merge(course_confirmation_row)
              else
                errors.add 'Multiple SIS import rows found matching confirmation row' if sis_import_rows.count > 1
                sis_import_rows.each do |sis_import_row|
                  merged_course_rows << sis_import_row.merge(course_confirmation_row)
                end
              end
            end
          end

          fill_in_sis_ids(merged_course_rows)
          fill_in_modular_flags(merged_course_rows)

          flag_co_taught_distinct_dates(merged_course_rows)

          merged_course_rows.each do |row|
            validate_and_add(merged_course_confirmations, row, %w(COURSE_ID LDAP_UID), strict: false)
          end

          log :info, "Merged all rows from department sheet '#{department_item.name}'"

          # Without a delay, this loop will hit enough sheets in quick succession to trigger API throttling.
          sleep Settings.oec.google.api_delay
        end

        course_confirmation_worksheets.each do |cc_worksheet|
          cc_worksheet[*Oec::Worksheets::CourseConfirmation::STATUS_CELL_COORDS] = 'Merged'
          cc_worksheet.save
        end

        log :info, "Updated confirmation/tracking sheet status"

        if !valid?
          log :warn, 'Confirmation sheets generated validation errors:'
          log_validation_errors
        end
        export_sheet(merged_course_confirmations, merged_confirmations_folder)
      end

      def fill_in_sis_ids(merged_sheet)
        rows_without_sis_id = merged_sheet.select { |r| r['SIS_ID'].blank? }
        uids = rows_without_sis_id.map { |r| r['LDAP_UID'] }
        user_data = CanvasCsv::Base.new().accumulate_user_data uids
        uid_to_sid = user_data.inject({}) do |hash, user|
          hash.update(user['login_id'] => user['user_id'])
        end
        rows_without_sis_id.each do |r|
          r['SIS_ID'] = uid_to_sid[r['LDAP_UID']]
        end
      end

      def fill_in_modular_flags(merged_sheet)
        merged_sheet.each do |row|
          row['MODULAR_COURSE'] = row.slice('START_DATE', 'END_DATE') == @term_dates ? nil : 'Y'
        end
      end

      def flag_co_taught_distinct_dates(merged_sheet)
        merged_sheet.group_by { |row| row['COURSE_ID'] }.each do |course_id, course_rows|
          rows_by_end_date = course_rows.group_by { |row| row['END_DATE'] }
          if rows_by_end_date.length > 1
            # Rows with distinct end dates must also have distinct instructors to be flagged.
            distinct_instructors = true
            uid_sets = []
            rows_by_end_date.each do |end_date, rows|
              uid_set = Set.new(rows.map { |r| r['LDAP_UID'] })
              if uid_sets.find { |comparison_set| uid_set.intersect?(comparison_set) } 
                distinct_instructors = false
                break
              end
              uid_sets << uid_set
            end
            next unless distinct_instructors
            course_rows.each do |r|
              m, d, y = r['END_DATE'].split('-')
              r['COURSE_ID'] = "#{r['COURSE_ID']}_#{y}#{m}#{d}"
              r['COURSE_ID_2'] = "#{r['COURSE_ID']}_#{y}#{m}#{d}"
              r['COURSE_NAME'] = "#{r['COURSE_NAME']} (#{y}#{m}#{d})"
              if r['CROSS_LISTED_NAME']
                r['CROSS_LISTED_NAME'] = "#{r['CROSS_LISTED_NAME']} (#{y}#{m}#{d})"
              end
            end
          end
        end
      end

      def infer_sis_values(confirmation_row)
        inferred = {
          'COURSE_ID_2' => confirmation_row['COURSE_ID'],
          'BLUE_ROLE' => '23'
        }
        if (m = confirmation_row['COURSE_NAME'].match /^(.*?)\s([A-Z]?\d+[A-Z]*)\s([A-Z]{3})\s(\d{3})/)
          inferred['DEPT_NAME'] = m[1]
          inferred['CATALOG_ID'] = m[2]
          inferred['INSTRUCTION_FORMAT'] = m[3]
          inferred['SECTION_NUM'] = m[4]
          # Deriving primary/secondary status from instruction format is a best guess, not a hard-and-fast business rule.
          # It will occasionally yield values that disagree with SIS data, but we're assured this is not a disaster for
          # OEC purposes.
          inferred['PRIMARY_SECONDARY_CD'] = case inferred['INSTRUCTION_FORMAT']
            when 'DIS', 'LAB', 'WBD'
              'S'
            else
              'P'
          end
        end
        inferred
      end

    end
  end
end
