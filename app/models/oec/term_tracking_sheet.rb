module Oec
  class TermTrackingSheet

    attr_accessor :term_code

    HEADER_ROW_INDEX = 2

    def initialize(remote_drive, term_code)
      @remote_drive = remote_drive
      @term_code = term_code
    end

    def departments_with_status(status)
      dept_names = []
      if (status_idx = get_header_index('Internal Status'))
        (HEADER_ROW_INDEX + 1).step do |y|
          worksheet = get_worksheet
          dept_name = worksheet[y, 1]
          break if dept_name.blank?
          if worksheet[y, status_idx] == status
            dept_names << dept_name
          end
        end
      end
      dept_names
    end

    def get_header_index(header)
      return unless (worksheet = get_worksheet)
	    1.step do |x|
        value = worksheet[HEADER_ROW_INDEX, x]
	      return x if value == header
	      break if value.blank?
	    end
    end

    def get_worksheet
      unless @worksheet
        term_folder = @remote_drive.find_first_matching_item @term_code
        tracking_sheet_item = @remote_drive.find_first_matching_item(self.name, term_folder)
        spreadsheet = tracking_sheet_item && @remote_drive.spreadsheet_by_id(tracking_sheet_item.id)
        @worksheet = spreadsheet && spreadsheet.worksheets.first
      end
      @worksheet
    end

    def name
      term_name = Berkeley::TermCodes.to_english(*@term_code.split('-'))
      "#{term_name} Course Evaluations Tracking Sheet"
    end

  end
end
