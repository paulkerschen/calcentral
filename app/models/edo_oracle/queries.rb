module EdoOracle
  class Queries < Connection
    include ActiveRecordHelper
    include ClassLogger
    include Concerns::QueryHelper

    ABSENTIA_CODE = 'OGPFABSENT'.freeze
    FILING_FEE_CODE = 'BGNNFILING'.freeze

    CANONICAL_SECTION_ORDERING = 'section_display_name, "primary" DESC, instruction_format, section_num'

    SECTION_COLUMNS = <<-SQL
      sec."id" AS section_id,
      sec."term-id" AS term_id,
      sec."session-id" AS session_id,
      TRIM(crs."title") AS course_title,
      TRIM(crs."transcriptTitle") AS course_title_short,
      crs."subjectArea" AS dept_name,
      crs."classSubjectArea" AS dept_code,
      crs."academicCareer-code" AS course_career_code,
      sec."primary" AS "primary",
      sec."sectionNumber" AS section_num,
      sec."component-code" AS instruction_format,
      sec."instructionMode-code" AS instruction_mode,
      TO_CHAR(sec."primaryAssociatedSectionId") AS primary_associated_section_id,
      sec."displayName" AS section_display_name,
      sec."topic-descr" AS topic_description,
      xlat."courseDisplayName" AS course_display_name,
      crs."catalogNumber-formatted" AS catalog_id,
      crs."catalogNumber-number" AS catalog_root,
      crs."catalogNumber-prefix" AS catalog_prefix,
      crs."catalogNumber-suffix" AS catalog_suffix
    SQL

    JOIN_SECTION_TO_COURSE = <<-SQL
      LEFT OUTER JOIN SISEDO.DISPLAYNAMEXLATV01_MVW xlat ON (
        xlat."classDisplayName" = sec."displayName")
      LEFT OUTER JOIN SISEDO.API_COURSEV01_MVW crs ON (
        xlat."courseDisplayName" = crs."displayName")
    SQL

    JOIN_ROSTER_TO_EMAIL = <<-SQL
       LEFT OUTER JOIN SISEDO.PERSON_EMAILV00_VW email ON (
         email."PERSON_KEY" = enroll."STUDENT_ID" AND
         email."EMAIL_PRIMARY" = 'Y')
    SQL

    def self.where_course_term
      sql_clause = <<-SQL
        AND term.ACAD_CAREER = crs."academicCareer-code"
        AND term.STRM = sec."term-id"
        AND CAST(crs."fromDate" AS DATE) <= term.TERM_END_DT
        AND CAST(crs."toDate" AS DATE) >= term.TERM_END_DT
      SQL
      sql_clause
    end

    def self.where_course_term_updated_date
      sql_clause = <<-SQL
        AND crs."updatedDate" = (
          SELECT MAX(crs2."updatedDate")
          FROM SISEDO.API_COURSEV01_MVW crs2, SISEDO.EXTENDED_TERM_MVW term2
          WHERE crs2."cms-version-independent-id" = crs."cms-version-independent-id"
          AND crs2."displayName" = crs."displayName"
          AND term2.ACAD_CAREER = crs."academicCareer-code"
          AND term2.STRM = sec."term-id"
          AND (
            (
              CAST(crs2."fromDate" AS DATE) <= term2.TERM_END_DT AND
              CAST(crs2."toDate" AS DATE) >= term2.TERM_END_DT
            )
            OR CAST(crs2."updatedDate" AS DATE) = TO_DATE('1901-01-01', 'YYYY-MM-DD')
          )
        )
      SQL
      sql_clause
    end

    def self.get_basic_people_attributes(up_to_1000_ldap_uids)
      safe_query <<-SQL
        select pi.ldap_uid, trim(pi.first_name) as first_name, trim(pi.last_name) as last_name, 
          pi.email_address, pi.student_id, pi.affiliations, pi.person_type, pi.alternateid
        from sisedo.calcentral_person_info_vw pi
        where pi.ldap_uid in (#{up_to_1000_ldap_uids.collect { |id| id.to_i }.join(', ')})
      SQL
    end

    def self.get_enrolled_sections(person_id, terms)
      # The push_pred hint below alerts Oracle to use indexes on SISEDO.API_COURSEV00_VW, aka crs.
      in_term_where_clause = "enr.\"TERM_ID\" IN (#{terms_query_list terms}) AND" unless terms.nil?
      safe_query <<-SQL
        SELECT DISTINCT
          #{SECTION_COLUMNS},
          sec."maxEnroll" AS enroll_limit,
          ENR.STDNT_ENRL_STATUS_CODE AS enroll_status,
          ENR.WAITLISTPOSITION AS waitlist_position,
          ENR.UNITS_TAKEN,
          ENR.UNITS_EARNED,
          ENR.GRADE_MARK AS grade,
          ENR.GRADE_POINTS AS grade_points,
          ENR.GRADING_BASIS_CODE AS grading_basis,
          ENR.ACAD_CAREER,
          CASE
            WHEN ENR.COURSE_CAREER = 'LAW'
            THEN ENR.RQMNT_DESIGNTN
            ELSE NULL
          END AS RQMNT_DESIGNTN
        FROM SISEDO.EXTENDED_TERM_MVW term,
             SISEDO.ETS_ENROLLMENTV01_VW enr
        JOIN SISEDO.CLASSSECTIONALLV01_MVW sec ON (
          enr."TERM_ID" = sec."term-id" AND
          enr."SESSION_ID" = sec."session-id" AND
          enr."CLASS_SECTION_ID" = sec."id" AND
          sec."status-code" IN ('A','S') )
        #{JOIN_SECTION_TO_COURSE}
        WHERE  #{in_term_where_clause}
          enr."CAMPUS_UID" = '#{person_id}'
          #{and_institution('enr')}
          AND enr."STDNT_ENRL_STATUS_CODE" != 'D'
          #{where_course_term}
          #{where_course_term_updated_date}
        ORDER BY term_id DESC, #{CANONICAL_SECTION_ORDERING}
      SQL
    end

    def self.get_instructing_sections(person_id, terms = nil)
      # Reduce performance hit and only add Terms whare clause if limiting number of terms pulled
      in_term_where_clause = " AND instr.\"term-id\" IN (#{terms_query_list terms})" unless terms.nil?
      safe_query <<-SQL
        SELECT
          #{SECTION_COLUMNS},
          sec."cs-course-id" AS cs_course_id,
          sec."maxEnroll" AS enroll_limit,
          sec."maxWaitlist" AS waitlist_limit,
          sec."startDate" AS start_date,
          sec."endDate" AS end_date
        FROM SISEDO.EXTENDED_TERM_MVW term,
             SISEDO.ASSIGNEDINSTRUCTORV00_VW instr
        JOIN SISEDO.CLASSSECTIONALLV01_MVW sec ON (
          instr."term-id" = sec."term-id" AND
          instr."session-id" = sec."session-id" AND
          instr."cs-course-id" = sec."cs-course-id" AND
          instr."offeringNumber" = sec."offeringNumber" AND
          instr."number" = sec."sectionNumber")
        #{JOIN_SECTION_TO_COURSE}
        WHERE sec."status-code" IN ('A','S')
          #{in_term_where_clause}
          AND instr."campus-uid" = '#{person_id}'
          #{where_course_term}
          #{where_course_term_updated_date}
        ORDER BY term_id DESC, #{CANONICAL_SECTION_ORDERING}
      SQL
    end

    def self.get_associated_secondary_sections(term_id, section_id)
      safe_query <<-SQL
        SELECT DISTINCT
          #{SECTION_COLUMNS},
          sec."cs-course-id" AS cs_course_id,
          sec."maxEnroll" AS enroll_limit,
          sec."maxWaitlist" AS waitlist_limit
        FROM SISEDO.CLASSSECTIONALLV01_MVW sec
        #{JOIN_SECTION_TO_COURSE}
        WHERE sec."status-code" IN ('A','S')
          AND sec."primary" = 'false'
          AND sec."term-id" = '#{term_id}'
          AND sec."primaryAssociatedSectionId" = '#{section_id}'
          #{where_course_term_updated_date}
        ORDER BY #{CANONICAL_SECTION_ORDERING}
      SQL
    end

    def self.get_section_meetings(term_id, section_id)
      safe_query <<-SQL
        SELECT DISTINCT
          sec."id" AS section_id,
          sec."printInScheduleOfClasses" AS print_in_schedule_of_classes,
          mtg."term-id" AS term_id,
          mtg."session-id" AS session_id,
          mtg."location-descr" AS location,
          mtg."meetsDays" AS meeting_days,
          mtg."startTime" AS meeting_start_time,
          mtg."endTime" AS meeting_end_time,
          mtg."startDate" AS meeting_start_date,
          mtg."endDate" AS meeting_end_date
        FROM
          SISEDO.MEETINGV00_VW mtg
        JOIN SISEDO.CLASSSECTIONALLV01_MVW sec ON (
          mtg."cs-course-id" = sec."cs-course-id" AND
          mtg."term-id" = sec."term-id" AND
          mtg."session-id" = sec."session-id" AND
          mtg."offeringNumber" = sec."offeringNumber" AND
          mtg."sectionNumber" = sec."sectionNumber"
        )
        WHERE
          sec."term-id" = '#{term_id}' AND
          sec."id" = '#{section_id}'
        ORDER BY meeting_start_date, meeting_start_time
      SQL
    end

    def self.get_sections_by_ids(term_id, section_ids)
      safe_query <<-SQL
        SELECT DISTINCT
          #{SECTION_COLUMNS}
        FROM SISEDO.CLASSSECTIONALLV01_MVW sec
        #{JOIN_SECTION_TO_COURSE}
        WHERE sec."term-id" = '#{term_id}'
          AND sec."id" IN (#{section_ids.collect { |id| id.to_i }.join(', ')})
          #{where_course_term_updated_date}
        ORDER BY #{CANONICAL_SECTION_ORDERING}
      SQL
    end

    def self.get_section_instructors(term_id, section_id)
      safe_query <<-SQL
        SELECT DISTINCT
          TRIM(instr."formattedName") AS person_name,
          TRIM(instr."givenName") AS first_name,
          TRIM(instr."familyName") AS last_name,
          instr."campus-uid" AS ldap_uid,
          instr."role-code" AS role_code,
          instr."role-descr" AS role_description,
          instr."gradeRosterAccess" AS grade_roster_access,
          instr."printInScheduleOfClasses" AS print_in_schedule
        FROM
          SISEDO.ASSIGNEDINSTRUCTORV00_VW instr
        JOIN SISEDO.CLASSSECTIONALLV01_MVW sec ON (
          instr."cs-course-id" = sec."cs-course-id" AND
          instr."term-id" = sec."term-id" AND
          instr."session-id" = sec."session-id" AND
          instr."offeringNumber" = sec."offeringNumber" AND
          instr."number" = sec."sectionNumber"
        )
        WHERE
          sec."id" = '#{section_id.to_s}' AND
          sec."term-id" = '#{term_id.to_s}' AND
          TRIM(instr."instructor-id") IS NOT NULL
        ORDER BY
          role_code
      SQL
    end

    # TODO: Update this and dependencies to require term
    def self.get_cross_listed_course_title(course_code)
      result = safe_query <<-SQL
        SELECT
          TRIM(crs."title") AS course_title,
          TRIM(crs."transcriptTitle") AS course_title_short
        FROM SISEDO.API_COURSEV01_MVW crs
        WHERE crs."updatedDate" = (
          SELECT MAX(CRS2."updatedDate") FROM SISEDO.API_COURSEV01_MVW crs2
          WHERE crs2."cms-version-independent-id" = crs."cms-version-independent-id"
          AND crs2."displayName" = crs."displayName"
        )
        AND crs."displayName" = '#{course_code}'
      SQL
      result.first if result
    end

    def self.get_subject_areas
      safe_query <<-SQL
        SELECT DISTINCT "subjectArea" FROM SISEDO.API_COURSEIDENTIFIERSV00_VW
      SQL
    end

    def self.get_enrolled_students(section_id, term_id)
      safe_query <<-SQL
        SELECT DISTINCT
          enroll."CAMPUS_UID" AS ldap_uid,
          enroll."STUDENT_ID" AS student_id,
          enroll."STDNT_ENRL_STATUS_CODE" AS enroll_status,
          enroll."WAITLISTPOSITION" AS waitlist_position,
          enroll."UNITS_TAKEN" AS units,
          TRIM(enroll."GRADING_BASIS_CODE") AS grading_basis
        FROM SISEDO.ETS_ENROLLMENTV01_VW enroll
        WHERE
          enroll."CLASS_SECTION_ID" = '#{section_id}'
          AND enroll."TERM_ID" = '#{term_id}'
          AND #{omit_drops_and_withdrawals}
      SQL
    end

    # Extended version of #get_enrolled_students used for rosters
    def self.get_rosters(ccns, term_id)
      if Settings.features.allow_alt_email_addr_for_enrollments
        join_roster_to_email = JOIN_ROSTER_TO_EMAIL
        email_col = ", email.\"EMAIL_EMAILADDRESS\" AS email_address"
      end

      safe_query <<-SQL
        SELECT DISTINCT
          enroll."CLASS_SECTION_ID" AS section_id,
          enroll."CAMPUS_UID" AS ldap_uid,
          enroll."STUDENT_ID" AS student_id,
          enroll."STDNT_ENRL_STATUS_CODE" AS enroll_status,
          enroll."WAITLISTPOSITION" AS waitlist_position,
          enroll."UNITS_TAKEN" AS units,
          enroll."ACAD_CAREER" AS academic_career,
          TRIM(enroll."GRADING_BASIS_CODE") AS grading_basis,
          plan."ACADPLAN_DESCR" AS major,
          plan."STATUSINPLAN_STATUS_CODE",
          stdgroup."HIGHEST_STDNT_GROUP" AS terms_in_attendance_group
          #{email_col}
        FROM SISEDO.ETS_ENROLLMENTV01_VW enroll
        LEFT OUTER JOIN
          SISEDO.STUDENT_PLAN_CC_V00_VW plan ON enroll."STUDENT_ID" = plan."STUDENT_ID" AND
          plan."ACADPLAN_TYPE_CODE" IN ('CRT', 'HS', 'MAJ', 'SP', 'SS')
        LEFT OUTER JOIN
          (
            SELECT s."STUDENT_ID", Max(s."STDNT_GROUP") AS "HIGHEST_STDNT_GROUP" FROM SISEDO.STUDENT_GROUPV01_VW s
            WHERE s."STDNT_GROUP" IN ('R1TA', 'R2TA', 'R3TA', 'R4TA', 'R5TA', 'R6TA', 'R7TA', 'R8TA')
            GROUP BY s."STUDENT_ID"
          ) stdgroup
          ON enroll."STUDENT_ID" = stdgroup."STUDENT_ID"
        #{join_roster_to_email}
        WHERE
          enroll."CLASS_SECTION_ID" IN ('#{ccns.join "','"}')
          AND enroll."TERM_ID" = '#{term_id}'
          AND #{omit_drops_and_withdrawals}
      SQL
    end

    def self.has_instructor_history?(ldap_uid, instructor_terms = nil)
      if instructor_terms.to_a.any?
        instructor_term_clause = "AND instr.\"term-id\" IN (#{terms_query_list instructor_terms.to_a})"
      end
      result = safe_query <<-SQL
        SELECT
          count(instr."term-id") AS course_count
        FROM
          SISEDO.ASSIGNEDINSTRUCTORV00_VW instr
        WHERE
          instr."campus-uid" = '#{ldap_uid}' AND
          rownum < 2
          #{instructor_term_clause}
      SQL
      if (result_row = result.first)
        Rails.logger.debug "Instructor #{ldap_uid} history for terms #{instructor_terms} count = #{result_row}"
        result_row['course_count'].to_i > 0
      else
        false
      end
    end

    def self.has_student_history?(ldap_uid, student_terms = nil)
      if student_terms.to_a.any?
        student_term_clause = "AND enroll.\"TERM_ID\" IN (#{terms_query_list student_terms.to_a})"
      end
      result = safe_query <<-SQL
        SELECT
          count(enroll."TERM_ID") AS enroll_count
        FROM
          SISEDO.ETS_ENROLLMENTV01_VW enroll
        WHERE
          enroll."CAMPUS_UID" = '#{ldap_uid.to_i}' AND
          rownum < 2
          #{student_term_clause}
      SQL
      if (result_row = result.first)
        Rails.logger.debug "Student #{ldap_uid} history for terms #{student_terms} count = #{result_row}"
        result_row['enroll_count'].to_i > 0
      else
        false
      end
    end

    # Used to create mapping between Legacy CCNs and CS Section IDs.
    def self.get_section_id(term_id, department, catalog_id, instruction_format, section_num)
      compressed_dept = SubjectAreas.compress department
      uglified_course_name = "#{compressed_dept} #{catalog_id}"
      rows = safe_query <<-SQL
        SELECT
          sec."id" AS section_id
        FROM
          SISEDO.CLASSSECTIONALLV01_MVW sec
        WHERE
          sec."term-id" = '#{term_id}' AND
          sec."component-code" = '#{instruction_format}' AND
          sec."displayName" = '#{uglified_course_name}' AND
          sec."sectionNumber" = '#{section_num}'
      SQL
      if (row = rows.first)
        row['section_id']
      end
    end

    def self.get_student_term_cpp(student_id)
      result = safe_query <<-SQL
        SELECT
          TERM_ID as term_id,
          ACAD_CAREER_CODE as acad_career,
          ACAD_CAREER_DESCR as acad_career_descr,
          ACAD_PROGRAM as acad_program,
          ACAD_PLAN as acad_plan
        FROM SISEDO.STUDENT_TERM_CPPV00_VW
        WHERE
          INSTITUTION = '#{UC_BERKELEY}' AND
          STUDENT_ID = '#{student_id}'
        ORDER BY TERM_ID DESC
      SQL
      return result
    end

    def self.get_undergrad_terms(oldest_term_id, opts={})
      sql = <<-SQL
        SELECT ACADCAREER_CODE as career_code,
          TERM_ID as term_id,
          TERM_TYPE as term_type,
          TERM_YEAR as term_year,
          TERM_CODE as term_code,
          TERM_DESCR as term_descr,
          TERM_BEGIN_DT as term_begin_date,
          TERM_END_DT as term_end_date,
          CLASS_BEGIN_DT as class_begin_date,
          CLASS_END_DT as class_end_date,
          INSTRUCTION_END_DT as instruction_end_date,
          GRADES_ENTERED_DT as grades_entered_date,
          END_DROP_ADD_DT as end_drop_add_date,
          IS_SUMMER as is_summer
        FROM  SISEDO.CLC_TERMV00_VW
        WHERE INSTITUTION = '#{UC_BERKELEY}' AND
          ACADCAREER_CODE = 'UGRD' AND
          TERM_TYPE IS NOT NULL AND
          TERM_ID >= '#{oldest_term_id}'
        ORDER BY TERM_ID DESC
      SQL
      safe_query(sql, opts)
    end

    def self.omit_drops_and_withdrawals
      # Late withdrawals are only indicated in primary section enrollments, and do not change
      # any values in secondary section enrollment rows. The CASE clause implements a
      # conditional join for secondary sections.
      <<-SQL
        enroll.STDNT_ENRL_STATUS_CODE != 'D' AND
        CASE enroll.GRADING_BASIS_CODE WHEN 'NON' THEN (
        SELECT DISTINCT prim_enr.GRADE_MARK
          FROM SISEDO.CLASSSECTIONALLV01_MVW sec
          LEFT JOIN SISEDO.ETS_ENROLLMENTV01_VW prim_enr
            ON prim_enr.CLASS_SECTION_ID = sec."primaryAssociatedSectionId"
            AND prim_enr.TERM_ID = enroll.TERM_ID
            AND prim_enr.STUDENT_ID = enroll.STUDENT_ID
            AND prim_enr.STDNT_ENRL_STATUS_CODE != 'D'
          WHERE sec."id" = enroll.CLASS_SECTION_ID
            AND sec."term-id" = enroll.TERM_ID
            AND prim_enr.STUDENT_ID IS NOT NULL
        )
        ELSE enroll.GRADE_MARK END != 'W'
      SQL
    end
  end
end
