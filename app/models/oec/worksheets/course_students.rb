module Oec
  module Worksheets
    class CourseStudents < Base

      def headers
        %w(
          COURSE_ID
          LDAP_UID
        )
      end

    end
  end
end
