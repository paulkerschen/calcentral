module Oec
  class MergeConfirmationSheetsTask < Task

    include Validator

    def run_internal
      term_folder = @remote_drive.find_first_matching_item @term_code
      imports_folder = @remote_drive.find_first_matching_item(Oec::Folder.sis_imports, term_folder)
      most_recent_import = @remote_drive.find_folders(imports_folder.id).sort_by(&:name).last
      raise UnexpectedDataError, "No SIS imports found for term #{@term_code}" unless most_recent_import

      confirmations_folder = @remote_drive.find_first_matching_item(Oec::Folder.confirmations, term_folder)
      raise UnexpectedDataError, "No '#{Oec::Folder.confirmations}' folder found for term #{@term_code}" unless confirmations_folder
      merged_confirmations_folder = @remote_drive.find_first_matching_item(Oec::Folder.merged_confirmations, term_folder)
      raise UnexpectedDataError, "No '#{Oec::Folder.merged_confirmations}' folder found for term #{@term_code}" unless merged_confirmations_folder

      merged_course_confirmations = Oec::SisImportSheet.new(export_name: 'Merged course confirmations', term_code: @term_code)

      department_names = Oec::DepartmentMappings.new(term_code: @term_code).by_dept_code(@departments_filter).keys.map { |code| Berkeley::Departments.get(code, concise: true) }

      @remote_drive.get_items_in_folder(confirmations_folder.id).each do |department_item|
        next unless department_names.include? department_item.name

        if (sis_import_sheet = @remote_drive.find_first_matching_item(department_item.name, most_recent_import))
          sis_import = Oec::SisImportSheet.from_csv(@remote_drive.export_csv(sis_import_sheet), term_code: @term_code)
        else
          raise UnexpectedDataError, "Could not find sheet '#{department_item.name}' in folder '#{most_recent_import.name}'"
        end

        confirmation_sheet = @remote_drive.spreadsheet_by_id department_item.id

        if (course_confirmation_worksheet = confirmation_sheet.worksheets.find { |w| w.title == 'Courses' })
          course_confirmation = Oec::CourseConfirmation.from_csv @remote_drive.export_csv(course_confirmation_worksheet)
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
              merged_course_rows << WorksheetRow.new({}, merged_course_confirmations).merge(course_confirmation_row)
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

        merged_course_rows.each do |row|
          validate_and_add(merged_course_confirmations, row, %w(COURSE_ID LDAP_UID), strict: false)
        end

        log :info, "Merged all rows from department sheet '#{department_item.name}'"

        # Without a delay, this loop will hit enough sheets in quick succession to trigger API throttling.
        sleep Settings.oec.google.api_delay
      end

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
      term_dates = default_term_dates
      merged_sheet.each do |row|
        row['MODULAR_COURSE'] = row.slice('START_DATE', 'END_DATE') == default_term_dates ? nil : 'Y'
      end
    end
  end
end
