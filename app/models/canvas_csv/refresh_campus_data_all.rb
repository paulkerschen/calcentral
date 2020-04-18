module CanvasCsv

  # Generates and imports SIS User and Enrollment CSV dumps into Canvas based on campus SIS information.
  class RefreshCampusDataAll < RefreshCampusDataBase

    def initialize
      super
      initialize_user_csvs
      initialize_term_enrollment_csvs
    end

    def import_type
      'all'
    end

    def generate_csv_files
      generate_users_csv do |users_csv|
        cached_enrollments_provider = CanvasCsv::TermEnrollments.new
        enrollment_term_csvs.each do |term, csv_filename|
          enrollments_csv = make_enrollments_csv(csv_filename)
          refresh_existing_term_sections(term, enrollments_csv, users_csv, cached_enrollments_provider)
          enrollments_csv.close
          enrollments_count = csv_count(csv_filename)
          logger.warn "Will upload #{enrollments_count} Canvas enrollment records for #{term}"
          enrollment_term_csvs[term] = nil if enrollments_count == 0
        end
      end
    end

    def refresh_existing_term_sections(term, enrollments_csv, users_csv, cached_enrollments_provider)
      canvas_sections_csv = Canvas::Report::Sections.new.get_csv(term)
      return if canvas_sections_csv.nil? || canvas_sections_csv.empty?
      # Instructure doesn't guarantee anything about sections-CSV ordering, but we need to group sections
      # together by course site.
      course_id_to_csv_rows = canvas_sections_csv.group_by {|row| row['course_id']}
      course_id_to_csv_rows.each do |course_id, csv_rows|
        logger.debug "Refreshing Course ID #{course_id}"
        if course_id.present?
          sis_section_ids = csv_rows.collect { |row| row['section_id'] }
          sis_section_ids.delete_if {|section| section.blank? }
          # Process using cached enrollment data. See CanvasCsv::TermEnrollments
          CanvasCsv::SiteMembershipsMaintainer.process(course_id, sis_section_ids, enrollments_csv, users_csv, @known_users, cached_enrollments_provider, @sis_user_id_changes)
        end
        logger.debug "Finished processing refresh for Course ID #{course_id}"
      end
    end

  end
end
