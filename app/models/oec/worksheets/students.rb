module Oec
  module Worksheets
    class Students < Base

      def headers
        %w(
          LDAP_UID
          SIS_ID
          FIRST_NAME
          LAST_NAME
          EMAIL_ADDRESS
        )
      end

      validate('SIS_ID') { |row| 'Unexpected' unless row['SIS_ID'] == "UID:#{row['LDAP_UID']}" || row['SIS_ID'] =~ /\A\d+\Z/ }

    end
  end
end
