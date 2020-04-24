module CanvasCsv

  # Generates and imports SIS User and Enrollment CSV dumps into Canvas based on campus SIS information.
  class RefreshCampusDataRecent < RefreshCampusDataBase
    require 'set'

    def initialize
      super
      initialize_user_csvs
      initialize_term_enrollment_csvs

      @canvas_sections = {}
      @enrollment_updates = {}
      @instructor_updates = {}
      @membership_updates_total = 0
      @primary_sections_to_update = {}
      @sis_user_id_changes = {}
      @uids_for_updates = Set.new
    end

    def import_type
      'recent'
    end

    def generate_csv_files
      fetch_recent_updates
      generate_users_csv(@uids_for_updates, cached: true) do |users_csv|
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

      instructor_results = EdoOracle::Bcourses.get_recent_instructor_updates(last_sync.last_instructor_sync, term_ids)
      collect_updates(instructor_results, @instructor_updates) do |row|
        EdoOracle::Adapters::Common.adapt_instructor_func row
        row['instructor_func']
      end
      enrollment_results = EdoOracle::Bcourses.get_recent_enrollment_updates(last_sync.last_enrollment_sync, term_ids)
      collect_updates(enrollment_results, @enrollment_updates) do |row|
        row['enroll_status']
      end
    end

    def collect_updates(edo_results, update_collector, &parse_status)
      edo_results.group_by{ |r| r['term_id'].to_s }.each do |term_id, rows|
        canvas_term_id = 'TERM:' + Berkeley::TermCodes.edo_id_to_code(term_id)
        update_collector[canvas_term_id] = {}
        rows.group_by { |r| r['section_id'].to_i.to_s }.each do |section_id, rows|
          update_collector[canvas_term_id][section_id] = {}
          rows.group_by { |r| r['ldap_uid'].to_s }.each do |ldap_uid, rows|
            next unless ldap_uid.present?
            @uids_for_updates.add ldap_uid
            update_collector[canvas_term_id][section_id][ldap_uid] = parse_status.call(rows[0])
          end
        end
      end
    end

    def refresh_term_enrollments(term_id, enrollments_csv, users_csv)
      # Download a Canvas sections report for the term and build our required data structure for section-to-course-site
      # associations.
      collect_section_data(term_id)

      # Loop through our cached term enrollments and collect any existing student enrollments or instructor assignments
      # affected by our update.
      existing_enrollments = {}
      existing_instructor_assignments = {}
      collect_cached_enrollments(term_id, existing_enrollments, existing_instructor_assignments)

      populate_update_csv(term_id, @instructor_updates, existing_instructor_assignments, enrollments_csv, users_csv) do |maintainer, row, status|
        campus_section = Canvas::Terms.sis_section_id_to_ccn_and_term(row['section_id'])
        maintainer.determine_instructor_role(@primary_sections_to_update[term_id][row['course_id']], campus_section, status)
      end

      populate_update_csv(term_id, @enrollment_updates, existing_enrollments, enrollments_csv, users_csv) do |maintainer, row, status|
        CanvasCsv::SiteMembershipsMaintainer::ENROLL_STATUS_TO_CANVAS_API_ROLE[status]
      end
    end

    def populate_update_csv(term_id, updates, existing_enrollments, enrollments_csv, users_csv, &determine_canvas_role)
      updates.fetch(term_id, {}).each do |ccn, status_by_uid|
        next unless @canvas_sections[term_id][ccn]
        status_by_uid.each do |ldap_uid, status|
          if @membership_updates_total > Settings.canvas_proxy.max_recent_membership_updates
            logger.warn "Hit threshold of #{@total_updates} updates; aborting further updates."
            return
          end
          @canvas_sections[term_id][ccn].each do |row|
            maintainer = CanvasCsv::SiteMembershipsMaintainer.new(
              row['course_id'], [row['section_id']], enrollments_csv, users_csv, @known_users, @sis_user_id_changes
            )
            previous_enrollments = existing_enrollments.fetch(ccn, {})
            next unless (canvas_api_role = determine_canvas_role.call(maintainer, row, status))
            if maintainer.update_section_enrollment_from_campus(canvas_api_role, row['section_id'], ldap_uid, previous_enrollments)
              # Remove any conflicting membership with a different role.
              maintainer.handle_missing_enrollments(ldap_uid, row['section_id'], previous_enrollments.fetch(ldap_uid, []))
              @membership_updates_total += 1
            end
          end
        end
      end
    end

    def collect_section_data(term_id)
      @canvas_sections[term_id] = {}
      campus_sections_for_instructor_updates = {}
      ccns_with_updates = (@instructor_updates[term_id] || {}).keys.to_set | (@enrollment_updates[term_id] || {}).keys.to_set

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
              @canvas_sections[term_id][campus_section[:ccn]] ||= []
              @canvas_sections[term_id][campus_section[:ccn]] << row
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
        all_primary_sections = Set.new
        @primary_sections_to_update[term_id] = {}
        campus_sections_for_instructor_updates.values.flatten.group_by {|sec| sec.slice(:term_yr, :term_cd)}.each do |term, sections|
          ccns = sections.collect { |sec| sec[:ccn] }
          section_rows = CanvasLti::SisAdapter.get_sections_by_ids(ccns, term[:term_yr], term[:term_cd])
          section_rows.select! { |row| row['primary_secondary_cd'] == 'P' }
          section_rows.map! { |row| term.merge(ccn: row['course_cntl_num']) }
          all_primary_sections.merge section_rows
        end
        campus_sections_for_instructor_updates.each do |course_id, sections|
          @primary_sections_to_update[term_id][course_id] = sections.select { |s| all_primary_sections.include? s }
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

      # Having looped through those cached term enrollments, we'll also need a subsequent loop through our more
      # recent exports.
      users_by_sis_id = accumulate_user_data(@uids_for_updates).index_by { |u| u['user_id'] }
      last_sync_timestamp = last_sync.latest_term_enrollment_csv_set.strftime('%Y%m%d%H%M%S')
      Dir.glob("#{@export_dir}/canvas-*-#{file_safe(term_id)}-enrollments-*.csv").sort.each do |enrollment_csv_path|
        next unless timestamp_from_filepath(enrollment_csv_path) > last_sync_timestamp
        logger.debug "Reading earlier update results from #{enrollment_csv_path}"
        CSV.foreach(enrollment_csv_path, headers: true) do |row|
          next unless row['status'] == 'active'
          next unless (campus_section = Canvas::Terms.sis_section_id_to_ccn_and_term(row['section_id']))
          if Canvas::Terms.term_to_sis_id(campus_section[:term_yr], campus_section[:term_cd]) == term_id
            logger.debug "Term matches, ccn #{campus_section[:ccn]}"
            existing_memberships = case row['role']
              when 'teacher', 'ta', 'Lead TA'
                existing_instructor_assignments
              when 'student', 'Waitlist Student'
                existing_enrollments
              else
                next
            end
            next unless (uid = users_by_sis_id.fetch(row['user_id'], {})['login_id'])
            logger.debug "UID #{uid}"
            existing_memberships[campus_section[:ccn]] ||= {}
            existing_memberships[campus_section[:ccn]][uid] ||= []
            translated_role = CanvasCsv::SiteMembershipsMaintainer::CANVAS_API_ROLE_TO_CANVAS_SIS_ROLE.invert[row['role']] || row['role']
            unless existing_memberships[campus_section[:ccn]][uid].find { |m| m['role'] == translated_role }
              # If we've found a membership for one of our updated UIDs that was already added in a previous job, add the bare minimum
              # required to tell downstream logic in SiteMembershipsMaintainer that it shouldn't try to add the membership again. Since
              # we're looking at a CSV that was created immediately before upload to Instructure, we don't know the SIS import ID (or
              # even that the SIS import succeeded), but a placeholder string indicates that there should have been such an import.
              existing_memberships[campus_section[:ccn]][uid] << {
                'role' => translated_role,
                'sis_import_id' => 'Cached on Junction'
              }
              logger.debug("Adding role #{translated_role}")
            end
          end
        end
      end
    end

  end
end
