module Canvas
  class SisImport < Proxy
    require 'csv'

    def initialize(options = {})
      super(options)
      @multipart_conn = multipart_conn
      @dry_run_import = Settings.canvas_proxy.dry_run_import
    end

    def multipart_conn
      conn = Faraday.new(ssl: {cert_store: SSL_CERTIFICATE_STORE}) do |c|
        c.request :multipart
        c.request :url_encoded
        c.adapter :net_http
      end
    end

    def import_all_term_enrollments(csv_file_path)
      import_with_check(csv_file_path)
    end

    def import_courses(csv_file_path)
      import_with_check(csv_file_path)
    end

    def import_sections(csv_file_path)
      import_with_check(csv_file_path)
    end

    def import_sis_ids(csv_file_path)
      import_with_check(csv_file_path)
    end

    def import_users(csv_file_path)
      import_with_check(csv_file_path)
    end

    def import_zipped(file_path)
      import_with_check(file_path, nil, 'zip')
    end

    def import_with_check(file_path, extra_params = '', file_type = 'csv')
      if @dry_run_import.present?
        logger.warn("DRY RUN MODE: Would import #{file_type} file #{file_path}")
        true
      else
        response = post_sis_import(file_path, extra_params, file_type)
        return false unless response
        status = import_status response['id']
        import_successful? status
      end
    end

    def post_sis_import(file_path, extra_params, file_type)
      if file_type == 'csv'
        content_type = 'text/csv'
      elsif file_type == 'zip'
        content_type = 'application/zip'
      else
        raise ArgumentError, "Unknown content type #{file_type}!"
      end
      upload_body = {attachment: Faraday::UploadIO.new(file_path, content_type)}
      url = "accounts/#{settings.account_id}/sis_imports.json?import_type=instructure_csv&extension=#{file_type}#{extra_params}"
      callstack = caller(0).inject([]) do |list, meth|
        meth.split(' ').last =~ /([a-z_]+)/
        list << $1
      end
      ActiveSupport::Notifications.instrument('proxy', { url: url, class: self.class, callstack: callstack[0..4] }) do
        response = raw_request(url, {
          method: :post,
          connection: @multipart_conn,
          body: upload_body
        })
        safe_json response[:body]
      end
    end

    def import_successful?(status)
      if status.blank? || status['progress'] != 100 || status['workflow_state'].start_with?('failed')
        logger.error "SIS import failed or incompletely processed; status: #{status}"
        false
      elsif status['workflow_state'] == 'imported'
        logger.warn "SIS import succeeded; status: #{status}"
        true
      elsif status['workflow_state'] == 'imported_with_messages'
        logger.warn "SIS import partially succeeded; status: #{status}"
        true
      else
        logger.error "Could not parse SIS import status: #{status}"
        false
      end
    end

    def generate_course_sis_id(canvas_course_id)
      sis_course_id = "C:#{canvas_course_id}"
      wrapped_put "courses/#{canvas_course_id}?course[sis_course_id]=#{sis_course_id}"
    end

    # import may not be completed the first time we ask for it, so loop until it is ready.
    def import_status(import_id)
      # We check for job completion every 20 seconds, and give up after this many minutes.
      max_loops = settings.sis_import_timeout * 3
      start_time = Time.now.to_i
      url = "accounts/#{settings.account_id}/sis_imports/#{import_id}"
      status = nil
      sleep 2
      begin
        Retriable.retriable(:on => Canvas::SisImport::ReportNotReadyException, :tries => max_loops, :interval => 20) do
          return false unless (response = wrapped_get url) && (status = response[:body])
          if %w(initializing created importing).include? status['workflow_state']
            logger.info "Import ID #{import_id} Status Report exists but is not yet ready; will retry later"
            raise Canvas::SisImport::ReportNotReadyException
          end
        end
      rescue Canvas::SisImport::ReportNotReadyException => e
        logger.error "Import ID #{import_id} Status Report not available after #{Time.now.to_i - start_time} secs, giving up"
      else
        elapsed_time = Time.now.to_i - start_time
        msg = "Import ID #{import_id} finished after #{elapsed_time} secs"
        if elapsed_time > 180
          logger.warn(msg)
        else
          logger.info(msg)
        end
      end
      status
    end

    class ReportNotReadyException < Exception; end

    private

    def mock_interactions
      on_request(uri_matching: "#{api_root}/courses/", method: :put)
        .respond_with_file('fixtures', 'json', 'canvas_put_sis_course_id.json')

      on_request(uri_matching: "#{api_root}/accounts/#{settings.account_id}/sis_imports/")
        .respond_with_file('fixtures', 'json', 'canvas_sis_import_status.json')
    end

  end
end
