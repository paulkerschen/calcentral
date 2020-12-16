module Oec
  module Tasks
    class TermSetup < Base

      def run_internal
        log :info, "Will create initial folders and files for term #{@term_code}"

        term_folder = create_folder @term_code
        term_subfolders = {}
        Oec::Folder::FOLDER_NAMES.each do |folder_type, folder_name|
          term_subfolders[folder_type] = create_folder(folder_name, term_folder)
        end

        previous_term_csvs = find_previous_term_csvs
        [Oec::Worksheets::CourseInstructors, Oec::Worksheets::CourseSupervisors, Oec::Worksheets::Instructors, Oec::Worksheets::Supervisors].each do |worksheet_class|
          file = previous_term_csvs[worksheet_class]
          if file && (file.mime_type == 'text/csv')
            content = StringIO.new
            @remote_drive.download(file, content)
            @remote_drive.upload_to_spreadsheet(file.name.chomp('.csv'), content, term_subfolders[:overrides].id)
          elsif file
            copy_file(file, term_subfolders[:overrides])
          else
            log :info, "Could not find previous sheet '#{worksheet_class.export_name}' for copying; will create header-only file"
            export_sheet_headers(worksheet_class, term_subfolders[:overrides])
          end
        end

        courses = Oec::Worksheets::Courses.new
        set_default_term_dates courses
        export_sheet(courses, term_subfolders[:overrides])

        if !@opts[:local_write] && (templates_folder = @remote_drive.find_first_matching_folder('templates'))
          if (department_template = @remote_drive.find_first_matching_item('Department confirmations', templates_folder))
            @remote_drive.copy_item_to_folder(department_template, term_subfolders[:confirmations].id, 'TEMPLATE')
          end
          if (tracking_sheet_template = @remote_drive.find_first_matching_item('Tracking sheet', templates_folder))
            tracking_sheet_copy = @remote_drive.copy_item_to_folder(tracking_sheet_template, term_folder.id, tracking_sheet_name)
            tracking_sheet = (s = @remote_drive.spreadsheet_by_id(tracking_sheet_copy.id)) && s.worksheets.first
            mappings = Oec::DepartmentMappings.new(term_code: @term_code).by_dept_code(include_in_oec: true)
            # Order departments alphabetically by concise name, with engineering separate.
            engineering_codes = %w(EFBIO EGCEE EHEEC EDDNO EIIEO EJMSM EKMEG ELNUC)
            codes = (mappings.keys - engineering_codes).sort_by { |c| Berkeley::Departments.get(c, concise: true) }
            codes.concat (engineering_codes & mappings.keys)
            codes.each_with_index do |dept_code, i|
              dept_heading = Berkeley::Departments.get(dept_code, concise: true)
              # FSSEM has too many course codes for notation to be useful.
              unless dept_code == 'FSSEM'
                dept_names = mappings[dept_code].map(&:dept_name).uniq.sort.join ', '
                dept_heading << " (#{dept_names})"
              end
              tracking_sheet[i+3, 1] = dept_heading
            end
            begin
              tracking_sheet.save
              log :debug, "Added department names to tracking sheet"
            rescue Errors::ProxyError => e
              log :error, "Failed to add department names to tracking sheet"
            end
          end
        end
      end

      def find_previous_term_csvs
        csvs = {}
        if (previous_term_folder = find_previous_term_folder)
          if (previous_overrides = @remote_drive.find_first_matching_folder(Oec::Folder.overrides, previous_term_folder))
            csvs[Oec::Worksheets::Instructors] = @remote_drive.find_first_matching_item('instructors', previous_overrides)
            csvs[Oec::Worksheets::Supervisors] = @remote_drive.find_first_matching_item('supervisors', previous_overrides)
          end
          if (previous_term_last_export = find_last_export previous_term_folder)
            csvs[Oec::Worksheets::CourseInstructors] = find_csv_in_folder(previous_term_last_export, 'course_instructors.csv')
            csvs[Oec::Worksheets::CourseSupervisors] = find_csv_in_folder(previous_term_last_export, 'course_supervisors.csv')
          end
        end
        csvs
      end

      def set_default_term_dates(courses)
        term = Berkeley::Terms.fetch.campus[Berkeley::TermCodes.to_slug *@term_code.split('-')]
        courses[0] = {
          'START_DATE' => @term_start.strftime(Oec::Worksheets::WORKSHEET_DATE_FORMAT),
          'END_DATE' => @term_end.strftime(Oec::Worksheets::WORKSHEET_DATE_FORMAT)
        }
      end
    end
  end
end
