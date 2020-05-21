module CanvasCsv

  # Generates and imports SIS User and Enrollment CSV dumps into Canvas based on campus SIS information.
  class RefreshCampusDataBase < Base
    attr_accessor :enrollment_term_csvs
    attr_accessor :users_csv_filename

    include Zipper

    def initialize
      super
      @enrollment_term_csvs = {}
      @known_users = {}
    end

    def initialize_user_csvs
      if Settings.canvas_proxy.import_zipped_csvs
        @sis_ids_csv_filename = "#{@export_dir}/canvas-#{DateTime.now.strftime('%F_%H%M%S')}-sis-ids.csv"
      end
      @users_csv_filename = "#{@export_dir}/canvas-#{DateTime.now.strftime('%F_%H%M%S')}-users-#{import_type}.csv"
    end

    def initialize_term_enrollment_csvs
      term_ids = Canvas::Terms.current_sis_term_ids
      term_ids.each do |term_id|
        csv_filename = "#{@export_dir}/canvas-#{DateTime.now.strftime('%F_%H%M%S')}-#{file_safe(term_id)}-enrollments-#{import_type}.csv"
        @enrollment_term_csvs[term_id] = csv_filename
      end
    end

    # Subclasses implement. At present this job comes in three flavors: 'accounts', 'all', and 'recent.'
    def import_type; end

    def run
      start_time = Time.now.utc
      generate_csv_files
      result = Settings.canvas_proxy.import_zipped_csvs ? import_zipped_csv_files : import_single_csv_files
      if result && import_type != 'accounts'
        Synchronization.get.update(
          last_enrollment_sync: start_time,
          last_instructor_sync: start_time
        )
      end
    end

    def generate_users_csv(uid_filter=nil, opts={})
      users_csv = make_users_csv(@users_csv_filename)
      sis_ids_csv = make_sis_ids_csv(@sis_ids_csv_filename) if @sis_ids_csv_filename

      user_maintainer = MaintainUsers.new(@known_users, users_csv, sis_ids_csv, opts)
      user_maintainer.refresh_existing_user_accounts(uid_filter)
      @sis_user_id_changes = user_maintainer.sis_user_id_changes

      if @sis_ids_csv_filename
        sis_ids_csv.close
        @sis_ids_csv_filename = nil if csv_count(@sis_ids_csv_filename) == 0
      end

      original_user_count = @known_users.length

      yield users_csv if block_given?
      users_csv.close

      new_user_count = @known_users.length - original_user_count
      updated_user_count = csv_count(@users_csv_filename) - new_user_count
      logger.warn "Will upload #{updated_user_count} changed accounts for #{original_user_count} existing users"
      logger.warn "Will upload #{new_user_count} new user accounts"
      @users_csv_filename = nil if (updated_user_count + new_user_count) == 0
    end

    def import_single_csv_files
      success = true
      import_proxy = Canvas::SisImport.new
      if @sis_ids_csv_filename.present? && import_proxy.import_sis_ids(@sis_ids_csv_filename)
        logger.warn 'SIS IDs import succeeded'
      end
      if @users_csv_filename.blank? || import_proxy.import_users(@users_csv_filename)
        logger.warn 'User import succeeded'

        enrollment_term_csvs.each do |term_id, csv_filename|
          if csv_filename.present?
            if import_proxy.import_all_term_enrollments(csv_filename)
              logger.warn "Incremental enrollment import for #{term_id} succeeded"
            else
              logger.error "Incremental enrollment import for #{term_id} failed"
              success = false
            end
          end
        end
      end
      success
    end

    def enrollments_import_safe?
      threshold = Settings.canvas_proxy.max_deleted_enrollments
      if threshold > 0
        for csv_file in enrollment_term_csvs.values
          if csv_file.present?
            enrollments_csv = CSV.read(csv_file, {headers: true})
            drops = enrollments_csv.count {|r| r['status'] == 'deleted'}
            if drops > threshold
              logger.error "Enrollments import #{csv_file} has #{drops} deletions; max is #{threshold}"
              return false
            end
          end
        end
      end
      true
    end

    def import_zipped_csv_files
      import_proxy = Canvas::SisImport.new
      import_files = [@sis_ids_csv_filename, @users_csv_filename]
      import_files.concat enrollment_term_csvs.values

      import_files.reject! { |f| f.blank? }
      if import_files.blank?
        logger.warn "No CSV files to import"
        return false
      end
      zipped_csv_filename = "#{@export_dir}/canvas-#{DateTime.now.strftime('%F_%H%M%S')}-incremental_#{import_type}.zip"
      zip_flattened(import_files, zipped_csv_filename)

      if !enrollments_import_safe?
        logger.error "Will not automatically import #{zipped_csv_filename}; import manually if desired"
        return false
      end

      if import_proxy.import_zipped zipped_csv_filename
        logger.warn "Import of #{zipped_csv_filename} succeeded, incorporating #{import_files}"
        true
      else
        logger.error "Failed import of #{zipped_csv_filename}, incorporating #{import_files}"
        false
      end
    end

  end
end
