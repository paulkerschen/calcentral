module CanvasLti
  # Prepares CSV export of official enrollments for use with E-Grades (UCB Online Grading System)
  #
  # All grades/scores for students enrolled in the Canvas course are prepared by #canvas_course_student_grades
  # #official_student_grades provides only the grades for the students officially enrolled in the section term/ccn specified.
  #
  class Egrades
    extend Cache::Cacheable
    include BackgroundJob
    include ClassLogger

    GRADE_TYPES = %w(final current)
    LETTER_GRADES = %w(A+ A A- B+ B B- C+ C C- D+ D D- F)

    def initialize(options = {})
      raise RuntimeError, 'canvas_course_id required' unless options.include?(:canvas_course_id)
      @canvas_course_id = options[:canvas_course_id]
      @canvas_official_course = CanvasLti::OfficialCourse.new(canvas_course_id: @canvas_course_id)
    end

    def official_student_grades_csv(term_cd, term_yr, ccn, type, pnp_cutoff)
      raise ArgumentError, 'type argument must be \'final\' or \'current\'' unless GRADE_TYPES.include?(type)
      # Campus Solutions expects Windows-style line endings.
      csv_string = CSV.generate(row_sep: "\r\n") do |csv|
        csv << ['ID', 'Name', 'Grade', 'Grading Basis', 'Comments']
        official_student_grades(term_cd, term_yr, ccn).each do |student|
          grade = convert_to_basis(student["#{type}_grade".to_sym].to_s, student[:grading_basis], pnp_cutoff)
          basis = student[:grading_basis] || ''
          comment = case student[:grading_basis]
            when 'GRD' then 'Opted for letter grade'
            when 'ESU', 'SUS' then 'S/U grade'
            when 'CNC' then 'C/NC grade'
            else ''
          end
          csv << [student[:student_id], student[:name], grade, basis, comment]
        end
      end
      # Prepend a space so that Excel does not tragically misinterpret the opening 'ID' column as a SYLK header.
      csv_string.prepend ' '
    end

    def official_student_grades(term_cd, term_yr, ccn)
      enrollments_by_uid = CanvasLti::SisAdapter.get_enrolled_students(ccn, term_yr, term_cd).index_by {|s| s['ldap_uid']}
      official_grades = []
      canvas_course_student_grades.each do |canvas_grades|
        next unless (enrollment = enrollments_by_uid[canvas_grades[:sis_login_id]])
        official_grades << canvas_grades.merge(
          grading_basis: enrollment['grading_basis'],
          student_id: enrollment['student_id']
        )
      end
      official_grades
    end

    def bg_canvas_course_student_grades(force = false)
      background_job_initialize
      background.canvas_course_student_grades(force)
    end

    def canvas_course_student_grades(force = false)
      logger.warn "Course student grades job started. Job state updated in cache key #{background_job_id}"
      self.class.fetch_from_cache("course-students-#{@canvas_course_id}", force) do
        proxy = Canvas::CourseUsers.new(course_id: @canvas_course_id, paging_callback: self)
        course_users = proxy.course_users(cache: false)[:body] || []
        course_users.map do |course_user|
          student_grade(course_user['enrollments']).slice(:current_grade, :final_grade).merge(
            name: course_user['sortable_name'],
            sis_login_id: course_user['login_id']
          )
        end
      end
    end

    def convert_to_basis(grade, basis, pnp_cutoff)
      if LETTER_GRADES.include?(grade) && %w(DPN EPN ESU PNP SUS).include?(basis) && pnp_cutoff != 'ignore'
        passing = LETTER_GRADES.index(grade) <= LETTER_GRADES.index(pnp_cutoff)
        case basis
          when 'DPN', 'EPN', 'PNP' then (passing ? 'P' : 'NP')
          when 'ESU', 'SUS' then (passing ? 'S' : 'U')
        end
      else
        grade
      end
    end

    # Extracts scores and grades from enrollments
    def student_grade(enrollments)
      grade = { :current_score => nil, :current_grade => nil, :final_score => nil, :final_grade => nil }
      return grade if enrollments.to_a.empty?
      enrollments.reject! {|e| e['type'] != 'StudentEnrollment' || !e.include?('grades') }
      return grade if enrollments.to_a.empty?
      grades = enrollments[0]['grades']
      # multiple student enrollments carry identical grades for course user in canvas
      grade[:current_score] = grades['current_score'] if grades.include?('current_score')
      grade[:current_grade] = grades['current_grade'] if grades.include?('current_grade')
      grade[:final_score] = grades['final_score'] if grades.include?('final_score')
      grade[:final_grade] = grades['final_grade'] if grades.include?('final_grade')
      grade
    end

    # Provides official sections associated with Canvas course
    def official_sections
      sec_ids = @canvas_official_course.official_section_identifiers
      return [] if sec_ids.empty?
      # A course site can only be provisioned to include sections from a specific term, so all terms should be the same for each section
      term = {
        term_yr: sec_ids[0][:term_yr],
        term_cd: sec_ids[0][:term_cd]
      }
      ccns = sec_ids.collect { |sec_id| sec_id[:ccn] }
      sections = CanvasLti::SisAdapter.get_sections_by_ids(ccns, term[:term_yr], term[:term_cd])
      # Ensure distinct section ids
      sections.uniq! { |s| s['course_cntl_num'] }
      retained_keys = %w(dept_name catalog_id instruction_format primary_secondary_cd section_num term_yr term_cd course_cntl_num)
      sections.collect do |sec|
        filtered_sec = sec.slice *retained_keys
        filtered_sec['display_name'] = "#{sec['dept_name']} #{sec['catalog_id']} #{sec['instruction_format']} #{sec['section_num']}"
        filtered_sec
      end
    end

    def export_options
      course_settings_worker = Canvas::CourseSettings.new(course_id: @canvas_course_id.to_i)
      if (course_settings = course_settings_worker.settings(cache: false)[:body])
        {
          :officialSections => official_sections,
          :gradingStandardEnabled => course_settings['grading_standard_enabled'],
          :sectionTerms => @canvas_official_course.section_terms,
        }
      end
    end

  end
end
