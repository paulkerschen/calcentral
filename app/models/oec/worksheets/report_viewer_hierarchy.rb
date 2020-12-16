module Oec
  module Worksheets
    class ReportViewerHierarchy < Base

      def headers
        %w(
          SOURCE
          TARGET
          ROLE_ID
        )
      end

    end
  end
end
