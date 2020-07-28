module DataLoch
  class Stocker
    include ClassLogger

    def s3_from_names(targets)
      return targets.map {|target| DataLoch::S3.new(target)}
    end

    def get_daily_path()
      today = (Settings.terms.fake_now || DateTime.now).in_time_zone.strftime('%Y-%m-%d')
      digest = Digest::MD5.hexdigest today
      "daily/#{digest}-#{today}"
    end

    def upload_advisor_relationships(s3_targets)
      logger.warn "Starting advisor relationships snapshot, targets #{s3_targets}."
      s3s = s3_from_names s3_targets
      instructor_advisor_path = DataLoch::Zipper.zip_query "instructor-advisor-map" do
        EdoOracle::Bulk.get_instructor_advisor_relationships
      end
      s3s.each {|s3| s3.upload("sis-sysadm/#{get_daily_path}/advisors/instructor-advisor-map", instructor_advisor_path) }

      student_advisor_path = DataLoch::Zipper.zip_query "student-advisor-map" do
        EdoOracle::Bulk.get_student_advisor_relationships
      end
      s3s.each {|s3| s3.upload("sis-sysadm/#{get_daily_path}/advisors/student-advisor-map", student_advisor_path) }

      advisor_note_permissions_path = DataLoch::Zipper.zip_query "advisor-note-permissions" do
        EdoOracle::Bulk.get_advisor_note_permissions
      end
      s3s.each {|s3| s3.upload("sis-sysadm/#{get_daily_path}/advisors/advisor-note-permissions", advisor_note_permissions_path) }

      academic_plan_owners_path = DataLoch::Zipper.zip_query "academic-plan-owners" do
        EdoOracle::Bulk.get_academic_plan_owners
      end
      s3s.each {|s3| s3.upload("sis-sysadm/#{get_daily_path}/advisors/academic-plan-owners", academic_plan_owners_path) }

      clean_tmp_files([instructor_advisor_path, student_advisor_path, advisor_note_permissions_path, academic_plan_owners_path])
      logger.info "Advisor snapshots complete."
    end

    def upload_undergrads(s3_targets)
      logger.warn "Starting active undergrads snapshot, targets #{s3_targets}."
      s3s = s3_from_names s3_targets
      undergrads_path = DataLoch::Zipper.zip_query "undergrads" do
        EdoOracle::Bulk.get_active_undergrads
      end
      s3s.each {|s3| s3.upload("undergrads", undergrads_path) }
      logger.info "Undergrads snapshot complete at #{undergrads_path}."
    end

    def upload_term_data(term_ids, s3_targets, is_historical=false)
      if is_historical
        data_type = 'historical'
        parent_path = 'historical'
      else
        data_type = 'daily'
        parent_path = get_daily_path
      end
      Rails.logger.warn "Starting #{data_type} course and enrollment data snapshot for term ids #{term_ids}, targets #{s3_targets}."
      s3s = s3_from_names s3_targets
      term_ids.each do |term_id|
        logger.info "Starting snapshots for term #{term_id}."
        courses_path = DataLoch::Zipper.zip_query "courses-#{term_id}" do
          EdoOracle::Bulk.get_courses(term_id)
        end
        s3s.each {|s3| s3.upload("#{parent_path}/courses", courses_path) }
        enrollments_path = DataLoch::Zipper.zip_query_with_batched_results "enrollments-#{term_id}" do |batch, size|
          EdoOracle::Bulk.get_batch_enrollments(term_id, batch, size)
        end
        s3s.each {|s3| s3.upload("#{parent_path}/enrollments", enrollments_path) }
        clean_tmp_files([courses_path, enrollments_path])
        logger.info "Snapshots complete for term #{term_id}."
      end
    end

    def upload_term_definitions(s3_targets)
      Rails.logger.warn "Starting term definition snapshots for targets #{s3_targets}."
      oldest_term_id = Berkeley::TermCodes.slug_to_edo_id(Settings.terms.oldest)
      s3s = s3_from_names s3_targets
      output_path = DataLoch::Zipper.zip_query "term_definitions" do
        EdoOracle::Bulk.get_undergrad_term_definitions(oldest_term_id)
      end
      s3s.each {|s3| s3.upload('term_definitions', output_path) }
      clean_tmp_files([output_path])
      logger.info "Term definitions snapshot complete at #{output_path}."
    end

    def upload_term_gpas(term_id, s3_targets)
      Rails.logger.warn "Starting historical Term GPAs snapshot for term id #{term_id}, targets #{s3_targets}."
      s3s = s3_from_names s3_targets
      logger.info "Starting GPA snapshots for term #{term_id}."
      output_path = DataLoch::Zipper.zip_query("term_gpa_#{term_id}", 'TSV') do
        EdoOracle::Bulk.get_term_gpas(term_id)
      end
      s3s.each {|s3| s3.upload('historical/gpa', output_path) }
      clean_tmp_files([output_path])
      logger.info "GPA snapshot complete for term #{term_id}."
    end

    def upload_advisee_data(s3_targets, jobs)
      # It seems safest to fetch the list of advisee SIDs from the same S3 environment which will receive their results,
      # but this could mean executing nearly the same large DB query multiple times in a row.
      # TODO Consider using the same SID list across environments.
      logger.warn "Starting #{jobs} data snapshot for targets #{s3_targets}."
      s3s = s3_from_names s3_targets
      previous_sids = nil
      job_paths = Hash[jobs.zip]
      s3s.each do |s3|
        sids = s3.load_advisee_sids()
        if sids != previous_sids
          jobs.each do |job|
            if job == 'demographics'
              # When faced with a large SELECT clause, SISEDO.PERSONV00_VW tends to faint dead away.
              job_paths[job] = DataLoch::Zipper.zip_query_sliced_matches(job, sids) do |subset|
                EdoOracle::Bulk.get_demographics subset
              end
            elsif job == 'academic_standing'
              job_paths[job] = DataLoch::Zipper.zip_query_sliced_matches(job, sids) do |subset|
                EdoOracle::Bulk.get_academic_standing subset
              end
            elsif job == 'basic_student_attributes'
              job_paths[job] = DataLoch::Zipper.zip_query_with_batched_results 'basic_student_attributes' do |batch, size|
                EdoOracle::Bulk.get_batch_basic_student_attributes(batch, size)
              end
            else
              job_paths[job] = DataLoch::Zipper.zip_query job do
                case job
                when 'intended_majors'
                  # The EDO intended majors view is already narrowed down to active undergraduates and needs no additional
                  # per-SID scoping.
                  EdoOracle::Bulk.get_intended_majors
                when 'edw_demographics'
                  EdwOracle::Queries.get_student_ethnicities sids
                when 'socio_econ'
                  EdwOracle::Queries.get_socio_econ sids
                when 'applicant_scores'
                  EdwOracle::Queries.get_applicant_scores sids
                else
                  Rails.logger.error "Got unknown job name #{job}!"
                end
              end
            end
          end
          previous_sids = sids
        end
        job_paths.each do |job, path|
          s3.upload("advisees/#{job}", path) if path
        end
      end
      clean_tmp_files(job_paths.values)
      logger.info "#{jobs} snapshots complete."
    end

    def upload_advising_notes_data(s3_targets, jobs)
      logger.warn "Starting SIS advising #{jobs} snapshot, targets #{s3_targets}."
      job_paths = Hash[jobs.zip]
      jobs.each do |job|
        job_paths[job] = DataLoch::Zipper.zip_query(job, 'JSON') do
          case job
          when 'notes'
            EdoOracle::Bulk.get_advising_notes
          when 'note-attachments'
            EdoOracle::Bulk.get_advising_note_attachments
          else
            logger.error "Got unknown job name #{job}!"
          end
        end
      end
      s3s = s3_from_names s3_targets
      s3s.each do |s3|
        job_paths.each do |job, path|
          s3.upload("sis-sysadm/#{get_daily_path}/advising-notes/#{job}", path) if path
        end
      end
      clean_tmp_files(job_paths.values)
      logger.info "#{jobs} snapshots complete."
    end

    # Let tests intercept the file deletion.
    def clean_tmp_files(paths)
      paths.each {|p| FileUtils.rm p}
    end

    def verify_endpoints(s3_targets)
      test_file = Zipper.staging_path 'ping.tmp'
      File.open(test_file, "w") {}
      s3_targets.each do |target|
        logger.info "Testing S3 advisee list access at #{target}"
        s3 = s3_from_names([target]).first
        s3.load_advisee_sids()
        logger.info "Testing upload access to #{target}"
        full_path = s3.upload('tmp', test_file)
        logger.info "Testing move access from #{full_path} to 'tmp/mved/ping.tmp'"
        s3.move(full_path, 'tmp/mved/ping.tmp')
      end
      logger.info "Access checked for AWS targets #{s3_targets}"
      clean_tmp_files [test_file]
    end

  end
end
