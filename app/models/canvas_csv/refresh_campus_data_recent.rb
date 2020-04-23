module CanvasCsv

  # Generates and imports SIS User and Enrollment CSV dumps into Canvas based on campus SIS information.
  class RefreshCampusDataRecent < RefreshCampusDataBase
    require 'set'

    def initialize
      super
      initialize_user_csvs
      initialize_term_enrollment_csvs
      @enrollment_updates = {}
      @instructor_updates = {}
      @known_users = {}
      @membership_updates_total = 0
      @sis_user_id_changes = {}
    end

    def import_type
      'recent'
    end

    def generate_csv_files
      uids_for_updates = fetch_recent_updates
      generate_users_csv(uids_for_updates, cached: true) do |users_csv|
        enrollment_term_csvs.each do |term_id, csv_filename|
          term_csv_count = 0
          if @instructor_updates[term_id] || @enrollment_updates[term_id]
            enrollments_csv = make_enrollments_csv(csv_filename)
            refresh_term_enrollments(term_id, enrollments_csv, users_csv)
            enrollments_csv.close
            term_csv_count = csv_count(csv_filename)
          end
          logger.warn "Will upload #{term_csv_count} Canvas enrollment records for #{term_id}"
          enrollment_term_csvs[term_id] = nil if term_csv_count == 0
        end
      end
    end

    def fetch_recent_updates
      # Query SISEDO for student enrollment and instructor assignment updates since the last sync, and build data structures
      # that can be easily cross-referenced with our cached Canvas enrollment data.
      last_sync = Synchronization.get
      term_ids = Canvas::Terms.current_terms.map &:campus_solutions_id
      uids_for_updates = Set.new

      instructor_results = EdoOracle::Bcourses.get_recent_instructor_updates(last_sync.last_instructor_sync, term_ids)
      instructor_results.group_by{ |r| r['term_id'].to_s }.each do |term_id, rows|
        canvas_term_id = 'TERM:' + Berkeley::TermCodes.edo_id_to_code(term_id)
        @instructor_updates[canvas_term_id] = {}
        rows.group_by { |r| r['section_id'].to_i.to_s }.each do |section_id, rows|
          @instructor_updates[canvas_term_id][section_id] = {}
          rows.group_by { |r| r['ldap_uid'].to_s }.each do |ldap_uid, rows|
            uids_for_updates.add ldap_uid
            EdoOracle::Adapters::Common.adapt_instructor_func rows[0]
            @instructor_updates[canvas_term_id][section_id][ldap_uid] = rows[0]['instructor_func']
          end
        end
      end

      enrollment_results = EdoOracle::Bcourses.get_recent_enrollment_updates(last_sync.last_enrollment_sync, term_ids)
      enrollment_results.group_by{ |r| r['term_id'].to_s }.each do |term_id, rows|
        canvas_term_id = 'TERM:' + Berkeley::TermCodes.edo_id_to_code(term_id)
        @enrollment_updates[canvas_term_id] = {}
        rows.group_by { |r| r['section_id'].to_i.to_s }.each do |section_id, rows|
          @enrollment_updates[canvas_term_id][section_id] = {}
          rows.group_by { |r| r['ldap_uid'].to_s }.each do |ldap_uid, rows|
            uids_for_updates.add ldap_uid
            @enrollment_updates[canvas_term_id][section_id][ldap_uid] = rows[0]['enroll_status']
          end
        end
      end

      uids_for_updates
    end

    def refresh_term_enrollments(term_id, enrollments_csv, users_csv)
      # Download a Canvas sections report for the term and build our required data structure for section-to-course-site
      # associations. Instructor updates require some extra information on all primary sections associated with the course site.
      canvas_sections_by_ccn = {}
      primary_sections_for_instructor_updates = {}
      collect_section_data(term_id, canvas_sections_by_ccn, primary_sections_for_instructor_updates)

      # Loop through our cached term enrollments and collect any existing student enrollments or instructor assignments
      # affected by our update.
      existing_enrollments = {}
      existing_instructor_assignments = {}
      collect_cached_enrollments(term_id, existing_enrollments, existing_instructor_assignments)

      # TODO Having looped through those cached term enrollments, we'll also need a subsequent loop through our more
      # recent exports.

      # Compare instructor updates to existing enrollments and write changes to CSV.
      @instructor_updates.fetch(term_id, {}).each do |ccn, instructor_func_by_uid|
        next unless canvas_sections_by_ccn[ccn]
        instructor_func_by_uid.each do |ldap_uid, instructor_func|
          if @membership_updates_total > Settings.canvas_proxy.max_recent_membership_updates
            logger.warn "Hit threshold of #{@total_updates} updates; aborting further updates."
            return
          end

          canvas_sections_by_ccn[ccn].each do |row|
            maintainer = CanvasCsv::SiteMembershipsMaintainer.new(
              row['course_id'], [row['section_id']], enrollments_csv, users_csv, @known_users, @sis_user_id_changes
            )
            campus_section = Canvas::Terms.sis_section_id_to_ccn_and_term(row['section_id'])
            canvas_api_role = maintainer.determine_instructor_role(
              primary_sections_for_instructor_updates[row['course_id']], campus_section, instructor_func
            )
            previous_assignments = existing_instructor_assignments.fetch(ccn, {})
            if maintainer.update_section_enrollment_from_campus(canvas_api_role, row['section_id'], ldap_uid, previous_assignments)
              # Remove any conflicting membership with a different role.
              maintainer.handle_missing_enrollments(ldap_uid, row['section_id'], previous_assignments.fetch(ldap_uid, []))
              @membership_updates_total += 1
            end
          end
        end
      end

      # Compare enrollment updates to existing enrollments and write changes to CSV.
      # TODO Is there an easy way to order CCNs by priority (undergrad over grad)?
      @enrollment_updates.fetch(term_id, {}).each do |ccn, enroll_status_by_uid|
        next unless canvas_sections_by_ccn[ccn]
        enroll_status_by_uid.each do |ldap_uid, enroll_status|
          next unless (canvas_api_role = CanvasCsv::SiteMembershipsMaintainer::ENROLL_STATUS_TO_CANVAS_API_ROLE[enroll_status])
          if @membership_updates_total > Settings.canvas_proxy.max_recent_membership_updates
            logger.warn "Hit threshold of #{@total_updates} updates; aborting further updates."
            return
          end

          canvas_sections_by_ccn[ccn].each do |row|
            maintainer = CanvasCsv::SiteMembershipsMaintainer.new(
              row['course_id'], [row['section_id']], enrollments_csv, users_csv, @known_users, @sis_user_id_changes
            )
            previous_enrollments = existing_enrollments.fetch(ccn, {})
            if maintainer.update_section_enrollment_from_campus(canvas_api_role, row['section_id'], ldap_uid, previous_enrollments)
              # Remove any conflicting membership with a different role.
              maintainer.handle_missing_enrollments(ldap_uid, row['section_id'], previous_enrollments.fetch(ldap_uid, []))
              @membership_updates_total += 1
            end
          end
        end
      end
    end

    def collect_section_data(term_id, canvas_sections_by_ccn, primary_sections_for_instructor_updates)
      campus_sections_for_instructor_updates = {}
      ccns_with_updates = (@instructor_updates[term_id] || []).keys.to_set | (@enrollment_updates[term_id] || []).keys.to_set

      if (canvas_sections_csv = Canvas::Report::Sections.new.get_csv(term_id))
        course_id_to_csv_rows = canvas_sections_csv.group_by {|row| row['course_id']}
        course_id_to_csv_rows.each do |course_id, rows|
          course_id_has_instructor_updates = false
          campus_sections_for_course = []
          rows.each do |row|
            next unless (campus_section = Canvas::Terms.sis_section_id_to_ccn_and_term(row['section_id']))
            section_term_id = Canvas::Terms.term_to_sis_id(campus_section[:term_yr], campus_section[:term_cd])
            campus_sections_for_course << campus_section
            if section_term_id == term_id && ccns_with_updates.include?(campus_section[:ccn])
              canvas_sections_by_ccn[campus_section[:ccn]] ||= []
              canvas_sections_by_ccn[campus_section[:ccn]] << row
              if @instructor_updates[term_id].has_key?(campus_section[:ccn])
                course_id_has_instructor_updates = true
              end
            end
          end
          if course_id_has_instructor_updates
            campus_sections_for_instructor_updates[course_id] = campus_sections_for_course
          end
        end

        # In order to determine proper instructor roles, we need a dictionary of all primary campus sections associated with
        # course sites where an instructor update has taken place. See SiteMembershipsMaintainer#site_primary_sections for
        # parallel logic.
        primary_sections = Set.new
        campus_sections_for_instructor_updates.values.flatten.group_by {|sec| sec.slice(:term_yr, :term_cd)}.each do |term, sections|
          ccns = sections.collect { |sec| sec[:ccn] }
          section_rows = CanvasLti::SisAdapter.get_sections_by_ids(ccns, term[:term_yr], term[:term_cd])
          section_rows.select! { |row| row['primary_secondary_cd'] == 'P' }
          section_rows.map! { |row| term.merge(ccn: row['course_cntl_num']) }
          primary_sections.merge section_rows
        end
        campus_sections_for_instructor_updates.each do |course_id, sections|
          primary_sections_for_instructor_updates[course_id] = sections.select { |s| primary_sections.include? s }
        end
      end
    end

    def collect_cached_enrollments(term_id, existing_enrollments, existing_instructor_assignments)
      cached_enrollments_provider = CanvasCsv::TermEnrollments.new
      last_sync = Synchronization.get
      filepath = cached_enrollments_provider.term_enrollments_csv_filepaths(last_sync.latest_term_enrollment_csv_set.to_date)[term_id]
      CSV.foreach(filepath, headers: true) do |row|
        next unless (campus_section = Canvas::Terms.sis_section_id_to_ccn_and_term(row['sis_section_id']))
        if Canvas::Terms.term_to_sis_id(campus_section[:term_yr], campus_section[:term_cd]) == term_id
          uid = row['sis_login_id'].to_s
          api_formatted_enrollment = CanvasCsv::TermEnrollments.csv_to_api_enrollment(row)
          if @instructor_updates.fetch(term_id, {}).fetch(campus_section[:ccn], {}).fetch(uid, nil)
            existing_instructor_assignments[campus_section[:ccn]] ||= {}
            existing_instructor_assignments[campus_section[:ccn]][uid] ||= []
            existing_instructor_assignments[campus_section[:ccn]][uid] << api_formatted_enrollment
          end
          if @enrollment_updates.fetch(term_id, {}).fetch(campus_section[:ccn], {}).fetch(uid, nil)
            existing_enrollments[campus_section[:ccn]] ||= {}
            existing_enrollments[campus_section[:ccn]][uid] ||= []
            existing_enrollments[campus_section[:ccn]][uid] << api_formatted_enrollment
          end
        end
      end
    end

  end
end
