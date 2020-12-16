module Oec
  module Worksheets
    class CourseSupervisors < Base

      def headers
        %w(
          COURSE_ID
          LDAP_UID
          DEPT_NAME
        )
      end

    end
  end
end
