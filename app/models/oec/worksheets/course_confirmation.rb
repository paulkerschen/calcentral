module Oec
  module Worksheets
    class CourseConfirmation < Base

      STATUS_CELL_COORDS = [1, 4]

      def export_name
        'Courses'
      end

      def headers
        %w(
          COURSE_ID
          COURSE_NAME
          CROSS_LISTED_FLAG
          CROSS_LISTED_NAME
          LDAP_UID
          FIRST_NAME
          LAST_NAME
          EMAIL_ADDRESS
          EVALUATE
          DEPT_FORM
          EVALUATION_TYPE
          START_DATE
          END_DATE
        )
      end

    end
  end
end
