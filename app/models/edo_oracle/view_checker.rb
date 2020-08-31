class EdoOracle::ViewChecker

  VIEW_DEPENDENCIES = [
    {
      :id => 'SISEDO.API_COURSEIDENTIFIERSV00_VW',
      :columns => ['subjectArea']
    },
    {
      :id => 'SISEDO.API_COURSEV01_MVW',
      :columns => %w(catalogNumber-formatted catalogNumber-number catalogNumber-prefix catalogNumber-suffix cms-id classSubjectArea displayName status-code subjectArea transcriptTitle title)
    },
    {
      :id => 'SISEDO.API_COURSEV01_MVW',
      :columns => %w(cms-version-independent-id displayName subjectArea classSubjectArea catalogNumber-formatted catalogNumber-number catalogNumber-prefix catalogNumber-suffix title transcriptTitle updatedDate fromDate toDate)
    },
    {
      :id => 'SISEDO.ASSIGNEDINSTRUCTORV00_VW',
      :columns => %w(campus-uid cs-course-id familyName formattedName givenName gradeRosterAccess instructor-id number offeringNumber printInScheduleOfClasses role-code role-descr session-id term-id)
    },
    {
      :id => 'SISEDO.CALCENTRAL_PERSON_INFO_VW',
      :columns => %w(LDAP_UID FIRST_NAME LAST_NAME EMAIL_ADDRESS STUDENT_ID AFFILIATIONS PERSON_TYPE)
    },
    {
      :id => 'SISEDO.CLASSSECTIONALLV01_MVW',
      :columns => %w(component-code cs-course-id displayName endDate finalExam id maxEnroll maxWaitlist primary primaryAssociatedSectionId printInScheduleOfClasses sectionNumber status-code session-id startDate term-id)
    },
    {
      :id => 'SISEDO.CLASSSECTIONALLV01_MVW',
      :columns => %w(id cs-course-id offeringNumber term-id session-id sectionNumber number component-code component-descr displayName instructionMode-code instructionMode-descr startDate endDate status-code status-descr classEnrollmentType-code classEnrollmentType-descr updatedDate cancelDate primary primaryAssociatedComponent primaryAssociatedSectionId enrollmentStatus-code enrollmentStatus-descr enrolledCount waitlistedCount minEnroll maxEnroll maxWaitlist instructorAddConsentRequired instructorDropConsentRequired printInScheduleOfClasses graded feesExist roomShare optionalSection contactHours finalExam topic-id topic-descr)
    },
    {
      :id => 'SISEDO.DISPLAYNAMEXLATV01_MVW',
      :columns => %w(classDisplayName courseDisplayName)
    },
    {
      :id => 'SISEDO.DISPLAYNAMEXLATV01_MVW',
      :columns => %w(courseDisplayName classDisplayName)
    },
    {
      :id => 'SISEDO.EXTENDED_TERM_MVW',
      :columns => %w(STRM TERM_END_DT)
    },
    {
      :id => 'SISEDO.MEETINGV00_VW',
      :columns => %w(cs-course-id endDate endTime location-descr meetsDays offeringNumber sectionNumber session-id startDate startTime term-id)
    },
    {
      :id => 'SISEDO.PERSON_EMAILV00_VW',
      :columns => %w(PERSON_KEY EMAIL_PRIMARY)
    },
    {
      :id => 'SISEDO.STUDENT_ACAD_STNDNGV00_VW',
      :columns => %w(STUDENT_ID ACADCAREER_CODE TERM_ID ACAD_STANDING_ACTION ACAD_STANDING_ACTION_DESCR OVERRIDE_MANUAL ACAD_PROGRAM ACAD_STANDING_STATUS ACAD_STANDING_STATUS_DESCR ACTION_DATE)
    },
    {
      :id => 'SISEDO.STUDENT_GROUPV01_VW',
      :columns => %w(STUDENT_ID STDNT_GROUP STDNT_GROUP_DESCR STDNT_GROUP_FROMDATE)
    },
    {
      :id => 'SISEDO.STUDENT_PLAN_CC_V00_VW',
      :columns => %w(STUDENT_ID ACADPLAN_CODE ACADPLAN_DESCR ACADPLAN_TYPE_CODE ACADPROG_CODE STATUSINPLAN_STATUS_CODE STATUSINPLAN_STATUS_DESCR STATUSINPLAN_ACTION_CODE STATUSINPLAN_ACTION_DESCR STATUSINPLAN_REASON_CODE STATUSINPLAN_REASON_DESCR ACADPLAN_FROMDATE)
    },
    {
      :id => 'SISEDO.STUDENT_TERM_CPPV00_VW',
      :columns => %w(TERM_ID INSTITUTION STUDENT_ID CAMPUS_ID ACAD_CAREER_CODE ACAD_CAREER_DESCR STUDENT_CAREER_NBR ACAD_PROGRAM ACAD_PROGRAM_DESCR ADMIT_TERM_ID EXP_GRAD_TERM_ID REQ_TERM_ID ACAD_PLAN ACAD_PLAN_TYPE ACAD_PLAN_DESCR ACAD_SUB_PLAN ACAD_SUBPLAN_DESCR DEGREE DEGREE_DESCR)
    },
  ]

  VIEW_DEPENDENCIES_CLC_SISEDO = [
    {
      :id => 'SISEDO.CLC_TERMV00_VW',
      :columns => %w(INSTITUTION ACADCAREER_CODE TERM_ID TERM_TYPE TERM_YEAR TERM_CODE TERM_DESCR TERM_BEGIN_DT TERM_END_DT CLASS_BEGIN_DT CLASS_END_DT INSTRUCTION_END_DT GRADES_ENTERED_DT FINAL_EXAM_WK_BEGIN_DT END_DROP_ADD_DT IS_SUMMER)
    }
  ]

  VIEW_DEPENDENCIES_JUNCTION = [
    {
      :id => 'SISEDO.ETS_ENROLLMENTV01_VW',
      :columns => %w(COURSE_CAREER RQMNT_DESIGNTN GRADE_MARK_MID STUDENT_ID CAMPUS_UID ACAD_CAREER INSTITUTION STDNT_ENRL_STATUS_CODE WAITLISTPOSITION UNITS_TAKEN UNITS_EARNED GRADE_MARK GRADING_BASIS_CODE TERM_ID SESSION_ID CLASS_SECTION_ID GRADE_POINTS)
    },
    {
      :id => 'SISEDO.STUDENT_PLANV01_VW',
      :columns => %w(ACADPLAN_CODE ACADPLAN_DESCR ACADPLAN_TYPE_CODE ACADPLAN_TYPE_DESCR ACADPLAN_OWNEDBY_CODE ACADPLAN_OWNEDBY_DESCR ACADPLAN_OWNED_BY_PCT ACADPROG_CODE ACADPROG_DESCR)
    },
    {
      :id => 'SYSADM.BOA_ADVISEE_NOTE00_VW',
      :columns => %w(EMPLID SAA_NOTE_ID SAA_SEQ_NBR ADVISOR_ID SCI_NOTE_PRIORITY SAA_NOTE_ITM_LONG SCC_ROW_ADD_OPRID SCC_ROW_ADD_DTTM SCC_ROW_UPD_OPRID SCC_ROW_UPD_DTTM SCI_APPT_ID SAA_NOTE_TYPE UC_ADV_TYP_DESC SAA_NOTE_SUBTYPE UC_ADV_SUBTYP_DESC SCI_TOPIC)
    },
    {
      :id => 'SYSADM.BOA_ADVISE_USERATTACHFILENAME00_VW',
      :columns => %w(EMPLID SAA_NOTE_ID ATTACHSYSFILENAME USERFILENAME)
    },
    {
      :id => 'SYSADM.BOA_ADV_NOTES_ACCESS_VW',
      :columns => %w(USER_ID CS_ID PERMISSION_LIST)
    },
    {
      :id => 'SYSADM.BOA_INSTRUCTOR_ADVISOR_VW',
      :columns => %w(ADVISOR_ID CAMPUS_ID INSTRUCTOR_ADISOR_NUMBER ADVISOR_TYPE ADVISOR_TYPE_DESCR INSTRUCTOR_TYPE INSTRUCTOR_TYPE_DESCR ACADEMIC_PROGRAM ACADEMIC_PROGRAM_DESCR ACADEMIC_PLAN ACADEMIC_PLAN_DESCR ACADEMIC_SUB_PLAN, ACADEMIC_SUB_PLAN_DESCR)
    },
    {
      :id => 'SYSADM.BOA_STUDENT_ADVISOR_VW',
      :columns => %w(STUDENT_ID CAMPUS_ID ADVISOR_ID ADVISOR_ROLE ADVISOR_ROLE_DESCR ACADEMIC_PROGRAM ACADEMIC_PROGRAM_DESCR ACADEMIC_PLAN ACADEMIC_PLAN_DESCR)
    }
  ]

  def initialize
    @report = {
      :successes => [],
      :errors => []
    }
    if ProvidedServices.calcentral?
      VIEW_DEPENDENCIES.concat VIEW_DEPENDENCIES_CLC_SISEDO
    end
    if ProvidedServices.bcourses?
      VIEW_DEPENDENCIES.concat VIEW_DEPENDENCIES_JUNCTION
    end
  end

  def perform_checks
    VIEW_DEPENDENCIES.each do |view|
      check_view(view)
    end
    @report
  end

  def check_view(view)
    query_string = "SELECT #{to_query_columns(view[:columns])} FROM #{view[:id]} WHERE rownum=1"
    results = EdoOracle::Queries.query(query_string)
    log_result(:successes, "#{view[:id]} has no issues") if results
  rescue => e
    log_result(:errors, "Failure to query #{view[:id]} - #{e.to_s}")
  end

  def log_result(type, message)
    @report[type].push(message)
  end

  def to_query_columns(column_names_array)
    column_names_array.map {|column_name|
      "\"#{column_name}\""
    }.join(',')
  end
end
