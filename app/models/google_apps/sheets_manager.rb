module GoogleApps
  class SheetsManager < DriveManager

    def initialize(app_id, uid, opts={})
      super(app_id, uid, opts)
      # See https://github.com/gimite/google-drive-ruby
      @session = GoogleDrive::Session.from_credentials(get_authorization)
    end

    def export_csv(file)
      if !file.respond_to?(:export_as_string) && file.respond_to?(:id) 
        file = spreadsheet_by_id(file.id)
      end
      if file.is_a? GoogleDrive::Spreadsheet
        file.export_as_string 'text/csv'
      elsif file.is_a? GoogleDrive::Worksheet
        file.export_as_string        
      else 
        raise Oec::UnexpectedDataError, "export_csv failed with file: #{file}"
      end
    end

    def spreadsheet_by_id(id)
      file = @session.file_by_id(id)
      raise Errors::ProxyError, "File is not a Google spreadsheet. Id: #{id}" unless file.is_a? GoogleDrive::Spreadsheet
      file
    rescue Google::Apis::ClientError => e
      log_transmission_error(e, "spreadsheets_by_id failed with id: #{id}")
      nil
    end

    def upload_to_spreadsheet(sheets_doc_name, path_or_io, parent_id, worksheet_title=nil)
      sheets_doc = upload_file(sheets_doc_name, '', parent_id, 'application/vnd.google-apps.spreadsheet', path_or_io, 'text/csv')
      spreadsheet = spreadsheet_by_id(sheets_doc.id)
      if worksheet_title.present?
        primary_worksheet = spreadsheet.worksheets.first
        primary_worksheet.title = worksheet_title
        primary_worksheet.save
      end
      spreadsheet
    rescue Google::Apis::ClientError => e
      log_transmission_error(e, "upload_to_spreadsheet failed with: #{[sheets_doc_name, path_or_io, parent_id].to_s}")
      raise e
    end

    private

    def log_transmission_error(e, message_prefix)
      # Log error message and Google::APIClient::Result body
      logger.error "#{message_prefix}\n  Exception: #{e}\n  Google error_message: #{e.result.error_message}\n  Google response.data: #{e.result.body}\n"
    end

  end
end
