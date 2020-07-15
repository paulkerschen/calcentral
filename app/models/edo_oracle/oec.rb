module EdoOracle
  class Oec < Connection
    include ActiveRecordHelper

    def self.get_courses(term_id, filter_clause)
      safe_query <<-SQL
      SELECT section_id, primary, instruction_format, section_num, course_display_name,
        ldap_uid, sis_id, role_code, course_title_short, enrollment_count,
         affiliations, cross_listed_ccns, co_scheduled_ccns,
         MIN(start_date) AS start_date, MAX(end_date) AS end_date from
      (
        SELECT DISTINCT
          sec."id" AS section_id,
          sec."primary" AS primary,
          sec."component-code" AS instruction_format,
          sec."sectionNumber" AS section_num,
          sec."displayName" AS course_display_name,
          instr."campus-uid" AS ldap_uid,
          instr."instructor-id" AS sis_id,
          instr."role-code" AS role_code,
          mtg."startDate" AS start_date,
          mtg."endDate" AS end_date,
          TRIM(crs."transcriptTitle") AS course_title_short,
          sec."enrolledCount" AS enrollment_count,
          (
            SELECT listagg("AFFILIATION_TYPE_CODE", ',') WITHIN GROUP (ORDER BY "AFFILIATION_TYPE_CODE")
            FROM SISEDO.PERSON_AFFILIATIONV00_VW aff
            WHERE
              aff."PERSON_KEY" = instr."instructor-id" AND
              aff."AFFILIATION_STATUS_CODE" = 'ACT' AND
              aff."AFFILIATION_TYPE_CODE" IN ('INSTRUCTOR', 'STUDENT')
          ) AS affiliations,
          (
            SELECT LISTAGG("id", ',') WITHIN GROUP (ORDER BY "id")
            FROM SISEDO.CLASSSECTIONALLV01_MVW sec2
            WHERE
              sec."cs-course-id" = sec2."cs-course-id" AND
              sec."term-id" = sec2."term-id" AND
              sec."session-id" = sec2."session-id" AND
              sec."sectionNumber" = sec2."sectionNumber"
          ) AS cross_listed_ccns,
          CASE mtg."location-code"
            WHEN ' ' THEN NULL
            WHEN 'INTR' THEN NULL ELSE (
            SELECT listagg("id", ',') WITHIN GROUP (ORDER BY "id")
            FROM SISEDO.MEETINGV00_VW mtg2 JOIN SISEDO.CLASSSECTIONALLV01_MVW sec3 ON (
              mtg2."location-code" = mtg."location-code" AND
              mtg2."meetsDays" = mtg."meetsDays" AND
              mtg2."startTime" = mtg."startTime" AND
              mtg2."endTime" = mtg."endTime" AND
              mtg2."startDate" = mtg."startDate" AND
              mtg2."endDate" = mtg."endDate" AND
              mtg2."cs-course-id" = sec3."cs-course-id" AND
              mtg2."term-id" = sec3."term-id" AND
              mtg2."session-id" = sec3."session-id" AND
              mtg2."offeringNumber" = sec3."offeringNumber" AND
              mtg2."sectionNumber" = sec3."sectionNumber")
            )
          END AS co_scheduled_ccns
        FROM
          SISEDO.CLASSSECTIONALLV01_MVW sec
          LEFT OUTER JOIN SISEDO.MEETINGV00_VW mtg ON (
            mtg."cs-course-id" = sec."cs-course-id" AND
            mtg."term-id" = sec."term-id" AND
            mtg."session-id" = sec."session-id" AND
            mtg."offeringNumber" = sec."offeringNumber" AND
            mtg."sectionNumber" = sec."sectionNumber")
          LEFT OUTER JOIN SISEDO.ASSIGNEDINSTRUCTORV00_VW instr ON (
            instr."cs-course-id" = sec."cs-course-id" AND
            instr."term-id" = sec."term-id" AND
            instr."session-id" = sec."session-id" AND
            instr."offeringNumber" = sec."offeringNumber" AND
            instr."number" = sec."sectionNumber")
          LEFT OUTER JOIN SISEDO.DISPLAYNAMEXLATV01_MVW xlat ON (
            xlat."classDisplayName" = sec."displayName")
          LEFT OUTER JOIN SISEDO.API_COURSEV01_MVW crs ON (
            xlat."courseDisplayName" = crs."displayName"
            AND crs."status-code" = 'ACTIVE')
          WHERE
            sec."term-id" = '#{term_id}'
            AND #{filter_clause}
            AND sec."status-code" IN ('A','S')
      )
      GROUP BY section_id, primary, instruction_format, section_num, course_display_name,
        ldap_uid, sis_id, role_code, course_title_short, enrollment_count,
        affiliations, cross_listed_ccns, co_scheduled_ccns
      SQL
    end

    # See http://www.oracle.com/technetwork/issue-archive/2006/06-sep/o56asktom-086197.html for explanation of
    # query batching with ROWNUM.
    def self.get_batch_enrollments(term_id, batch_number, batch_size)
      mininum_row_exclusive = (batch_number * batch_size)
      maximum_row_inclusive = mininum_row_exclusive + batch_size
      # Dealing with late withdrawals for secondary sections (the long CASE clause) almost quadruples
      # the query's time.
      # TODO Restructure code to avoid secondary-section fetches for primary-section enrollments with GRADE_MARK 'W'.
      sql = <<-SQL
        SELECT * FROM (
          SELECT /*+ FIRST_ROWS(n) */ enrollments.*, ROWNUM rnum FROM (
            SELECT DISTINCT
              enroll.CLASS_SECTION_ID as section_id,
              enroll.CAMPUS_UID AS ldap_uid,
              enroll.STUDENT_ID AS sis_id
            FROM SISEDO.ETS_ENROLLMENTV01_VW enroll
            WHERE
              enroll.TERM_ID = '#{term_id}'
              AND enroll.STDNT_ENRL_STATUS_CODE = 'E'
              AND CASE enroll.GRADING_BASIS_CODE 
                WHEN 'NON' THEN (
                  SELECT DISTINCT prim_enr.GRADE_MARK
                    FROM SISEDO.CLASSSECTIONALLV01_MVW sec
                    LEFT JOIN SISEDO.ETS_ENROLLMENTV01_VW prim_enr
                      ON  prim_enr.CLASS_SECTION_ID = sec."primaryAssociatedSectionId"
                      AND prim_enr.TERM_ID = enroll.TERM_ID
                      AND prim_enr.STUDENT_ID = enroll.STUDENT_ID
                      AND prim_enr.STDNT_ENRL_STATUS_CODE = 'E'
                    WHERE sec."id" = enroll.CLASS_SECTION_ID AND sec."term-id" = enroll.TERM_ID
                      AND prim_enr.STUDENT_ID IS NOT NULL
                )
              ELSE enroll.GRADE_MARK END != 'W'
            ORDER BY section_id, sis_id
          ) enrollments
          WHERE ROWNUM <= #{maximum_row_inclusive}
        )
        WHERE rnum > #{mininum_row_exclusive}
      SQL
      # Result sets are too large for bulk stringification.
      safe_query(sql, do_not_stringify: true)
    end

    # Used to generate the Oec::SisImportTask query.
    # Awkward substring matches on sec."displayName" are necessary because the better-parsed dept_name and catalog_id
    # fields are derived from a join and not guaranteed to be present.
    def self.depts_clause(term_code, course_codes)
      return if course_codes.blank?
      department_mappings = ::Oec::DepartmentMappings.new(term_code: term_code)
      subclauses = course_codes.group_by(&:dept_name).map do |dept_name, codes|
        subclause = ''
        if (default_code = codes.find { |code| code.catalog_id.blank? })
          subclause << "sec.\"displayName\" LIKE '#{SubjectAreas.compress dept_name} %'"
          # Exclude any catalog IDs that are explicitly mapped to other departments, or which have been
          # explicitly excluded from OEC.
          excluded_codes = department_mappings.excluded_courses(dept_name, default_code.dept_code)
          if excluded_codes.any?
            excluded_codes.each do |code|
              subclause << " and sec.\"displayName\" != '#{SubjectAreas.compress dept_name} #{code.catalog_id}'"
            end
          end
        else
          # No catalog IDs are included by default; note explicit inclusions
          included_codes = codes.select &:include_in_oec
          if included_codes.any?
            subclause << included_codes.map { |code| "sec.\"displayName\" = '#{SubjectAreas.compress dept_name} #{code.catalog_id}'" }.join(' or ')
          end
        end
        subclause
      end
      subclauses.reject! &:blank?
      case subclauses.count
        when 0
          nil
        when 1
          "(#{subclauses.first})"
        else
          "(#{subclauses.map { |subclause| "(#{subclause})" }.join(' or ')})"
      end
    end

    # Find courses associated with Freshman & Sophomore Seminars, which have no direct expression in the Oracle DB.
    # If another RegExp-based "virtual department" ever shows up, we should generalize support.
    def self.get_fssem_course_codes(term_id)
      filter_clause = <<-FLTR
        (
          REGEXP_LIKE( sec."displayName", ' (39|24|84)[A-Z]*$') OR
          REGEXP_LIKE( sec."displayName", '(MCELLBI|NATAMST) 90[A-Z]*$')
        )
      FLTR
      rows = safe_query <<-SQL
        SELECT DISTINCT
          sec."displayName" AS course_display_name
        FROM
          SISEDO.CLASSSECTIONALLV01_MVW sec
          LEFT OUTER JOIN SISEDO.DISPLAYNAMEXLATV01_MVW xlat ON (
            xlat."classDisplayName" = sec."displayName")
          LEFT OUTER JOIN SISEDO.API_COURSEV01_MVW crs ON (
            xlat."courseDisplayName" = crs."displayName"
            AND crs."status-code" = 'ACTIVE')
          WHERE
            sec."term-id" = '#{term_id}'
            AND #{filter_clause}
            AND sec."status-code" IN ('A','S')
          ORDER BY course_display_name ASC
      SQL
      # TODO A number of classes outside the EdoOracle::UserCourses module now rely on the parse_course_code method.
      # Shouldn't it be moved to a more central location?
      parser = EdoOracle::UserCourses::Base.new
      rows.collect do |row|
        dept_name, dept_code, catalog_id = parser.parse_course_code row
        {dept_name: dept_name, catalog_id: catalog_id}
      end
    end

    def self.course_ccn_column
      'sec."id"'
    end

    def self.enrollment_ccn_column
      'enroll."CLASS_SECTION_ID"'
    end

  end
end

