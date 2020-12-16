module Oec
  module Tasks 
    class Validation < Base

      include MergedSheetValidation

      def run_internal
        build_and_validate_export_sheets
      end

    end
  end
end
