module Oec
  class Courses < Worksheet

    def headers
      %w(
        COURSE_ID
        COURSE_ID_2
        COURSE_NAME
        CROSS_LISTED_FLAG
        CROSS_LISTED_NAME
        DEPT_NAME
        CATALOG_ID
        INSTRUCTION_FORMAT
        SECTION_NUM
        PRIMARY_SECONDARY_CD
        EVALUATE
        DEPT_FORM
        EVALUATION_TYPE
        MODULAR_COURSE
        START_DATE
        END_DATE
        CANVAS_COURSE_ID
        QB_MAPPING
      )
    end

    validate('COURSE_ID') { |row| 'Invalid' unless row['COURSE_ID'] =~ /\A20\d{2}-[ABCD]-\d{5}(_(A|B|GSI|CHEM|MCB|MID))?\Z/ }
    validate('COURSE_ID_2') { |row| 'Non-matching' unless row['COURSE_ID'] == row['COURSE_ID_2'] }

    validate('END_DATE') do |row|
      start_date = Date.strptime(row['START_DATE'], WORKSHEET_DATE_FORMAT)
      end_date = Date.strptime(row['END_DATE'], WORKSHEET_DATE_FORMAT)
      if start_date > end_date
        "START_DATE #{row['START_DATE']} later than"
      elsif start_date == end_date
        "START_DATE #{row['START_DATE']} equal to"
      end
    end

    validate('EVALUATION_TYPE') do |row|
      if row['COURSE_ID'].end_with?('_GSI') && !row['DEPT_FORM'].in?(%w(LAW SPANISH)) && row['EVALUATION_TYPE'] != 'G'
        'Unexpected for _GSI course:'
      end
    end
  end
end
