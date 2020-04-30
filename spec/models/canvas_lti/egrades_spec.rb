describe CanvasLti::Egrades do
  let(:canvas_course_id)          { 1276293 }
  let(:canvas_course_section_id)  { 1312012 }

  subject { CanvasLti::Egrades.new(canvas_course_id: canvas_course_id) }

  let(:course_assignments) {
    [
      {
        'id' => 19082,
        'name' => 'Assignment 1',
        'muted' => false,
        'due_at' => '2015-05-12T19:40:00Z',
        'points_possible' => 100
      },
      {
        'id' => 19083,
        'name' => 'Assignment 2',
        'muted' => true,
        'due_at' => '2015-10-13T06:05:00Z',
        'points_possible' => 50
      },
      {
        'id' => 19084,
        'name' => 'Assignment 3',
        'muted' => false,
        'due_at' => nil,
        'points_possible' => 25
      },
    ]
  }

  it_should_behave_like 'a background job worker'

  context 'when serving official student grades csv' do
    let(:official_student_grades_list) do
      [
        {sis_login_id: '872584', final_grade: 'F', current_grade: 'C', grading_basis: 'GRD', student_id: '2004491', name: 'Gregory, Matt'},
        {sis_login_id: '4000123', final_grade: 'C', current_grade: 'C', grading_basis: 'ESU', student_id: '24000123', name: 'Lyons, Marcus'},
        {sis_login_id: '872527', final_grade: 'D-', current_grade: 'C', grading_basis: 'DPN', student_id: '2004445', name: 'Tarpey, Luke'},
        {sis_login_id: '872529', final_grade: 'D-', current_grade: 'C', grading_basis: 'GRD', student_id: '2004421', name: 'MacDougall, Johnny'}
      ]
    end

    before do
      allow(subject).to receive(:official_student_grades).with('B', '2017', '7309').and_return official_student_grades_list
    end

    it 'raises error when called with invalid type argument' do
      expect {
        subject.official_student_grades_csv('B', '2017', '7309', 'finished', 'D-')
      }.to raise_error(ArgumentError, 'type argument must be \'final\' or \'current\'')
    end

    let(:pnp_cutoff) { 'D' }
    let(:official_grades_csv_string) { subject.official_student_grades_csv('B', '2017', '7309', grade_type, pnp_cutoff) }
    let(:official_grades_csv) { CSV.parse official_grades_csv_string.strip, headers: true }

    context 'current grades' do
      let(:grade_type) { 'current' }

      it 'outputs CSV with CR/LF line breaks' do
        expect(official_grades_csv_string.split "\r\n").to have(5).items
      end

      it 'prepends a space' do
        expect(official_grades_csv_string).to start_with ' '
      end

      it 'returns current grades' do
        expect(official_grades_csv.count).to eq 4
        expect(official_grades_csv[0]['ID']).to eq '2004491'
        expect(official_grades_csv[0]['Name']).to eq 'Gregory, Matt'
        expect(official_grades_csv[0]['Grade']).to eq 'C'
        expect(official_grades_csv[0]['Grading Basis']).to eq 'GRD'
        expect(official_grades_csv[0]['Comments']).to eq 'Opted for letter grade'

        expect(official_grades_csv[2]['ID']).to eq '2004445'
        expect(official_grades_csv[2]['Name']).to eq 'Tarpey, Luke'
        expect(official_grades_csv[2]['Grade']).to eq 'P'
        expect(official_grades_csv[2]['Grading Basis']).to eq 'DPN'
        expect(official_grades_csv[2]['Comments']).to eq ''

        expect(official_grades_csv[3]['ID']).to eq '2004421'
        expect(official_grades_csv[3]['Name']).to eq 'MacDougall, Johnny'
        expect(official_grades_csv[3]['Grade']).to eq 'C'
        expect(official_grades_csv[3]['Grading Basis']).to eq 'GRD'
        expect(official_grades_csv[3]['Comments']).to eq 'Opted for letter grade'
      end

      context 'a lax P/NP cutoff' do
        let(:pnp_cutoff) { 'D' }
        it 'respects cutoff per grading basis' do
          expect(official_grades_csv[1]['Grade']).to eq 'S'
          expect(official_grades_csv[1]['Grading Basis']).to eq 'ESU'
          expect(official_grades_csv[2]['Grade']).to eq 'P'
          expect(official_grades_csv[2]['Grading Basis']).to eq 'DPN'
        end
      end

      context 'a strict P/NP cutoff' do
        let(:pnp_cutoff) { 'B-' }
        it 'respects cutoff per grading basis' do
          expect(official_grades_csv[1]['Grade']).to eq 'U'
          expect(official_grades_csv[1]['Grading Basis']).to eq 'ESU'
          expect(official_grades_csv[2]['Grade']).to eq 'NP'
          expect(official_grades_csv[2]['Grading Basis']).to eq 'DPN'
        end
      end

      context 'P/NP conversion disabled' do
        let(:pnp_cutoff) { 'ignore' }
        it 'retains original letter grades' do
          expect(official_grades_csv[1]['Grade']).to eq 'C'
          expect(official_grades_csv[1]['Grading Basis']).to eq 'ESU'
          expect(official_grades_csv[2]['Grade']).to eq 'C'
          expect(official_grades_csv[2]['Grading Basis']).to eq 'DPN'
        end
      end
    end

    context 'final grades' do
      let(:grade_type) { 'final' }

      it 'returns final grades' do
        expect(official_grades_csv.count).to eq 4
        expect(official_grades_csv[0]['ID']).to eq '2004491'
        expect(official_grades_csv[0]['Name']).to eq 'Gregory, Matt'
        expect(official_grades_csv[0]['Grade']).to eq 'F'
        expect(official_grades_csv[0]['Grading Basis']).to eq 'GRD'
        expect(official_grades_csv[0]['Comments']).to eq 'Opted for letter grade'

        expect(official_grades_csv[2]['ID']).to eq '2004445'
        expect(official_grades_csv[2]['Name']).to eq 'Tarpey, Luke'
        expect(official_grades_csv[2]['Grade']).to eq 'NP'
        expect(official_grades_csv[2]['Grading Basis']).to eq 'DPN'
        expect(official_grades_csv[2]['Comments']).to eq ''

        expect(official_grades_csv[3]['ID']).to eq '2004421'
        expect(official_grades_csv[3]['Name']).to eq 'MacDougall, Johnny'
        expect(official_grades_csv[3]['Grade']).to eq 'D-'
        expect(official_grades_csv[3]['Grading Basis']).to eq 'GRD'
        expect(official_grades_csv[3]['Comments']).to eq 'Opted for letter grade'
      end
    end
  end

  context 'when serving official student grades' do
    let(:primary_section_enrollees) do
      [
        {'ldap_uid' => '872584', 'enroll_status' => 'E', 'student_id' => '2004491', 'grading_basis' => 'GRD'},
        {'ldap_uid' => '872527', 'enroll_status' => 'E', 'student_id' => '2004445', 'grading_basis' => 'GRD'},
        {'ldap_uid' => '872529', 'enroll_status' => 'E', 'student_id' => '2004421', 'grading_basis' => 'PNP'},
      ]
    end

    let(:canvas_course_student_grades_list) do
      [
        {:sis_login_id => '872584', :final_grade => 'F', :current_grade => 'C'},
        {:sis_login_id => '4000123', :final_grade => 'B', :current_grade => 'B'},
        {:sis_login_id => '872527', :final_grade => 'A+', :current_grade => 'A+'},
        {:sis_login_id => '872529', :final_grade => 'D-', :current_grade => 'C'},
      ]
    end

    before do
      allow(CanvasLti::SisAdapter).to receive(:get_enrolled_students).with('7309', '2017', 'B').and_return primary_section_enrollees
      allow(subject).to receive(:canvas_course_student_grades).and_return canvas_course_student_grades_list
    end
    it 'only provides grades for official enrollees in section specified' do
      result = subject.official_student_grades('B', '2017', '7309')
      expect(result.count).to eq 3
      expect(result[0][:sis_login_id]).to eq '872584'
      expect(result[1][:sis_login_id]).to eq '872527'
      expect(result[2][:sis_login_id]).to eq '872529'
    end

    it 'includes student IDs' do
      result = subject.official_student_grades('B', '2017', '7309')
      expect(result.count).to eq 3
      expect(result[0][:student_id]).to eq '2004491'
      expect(result[1][:student_id]).to eq '2004445'
      expect(result[2][:student_id]).to eq '2004421'
    end
  end

  context 'when providing canvas course student grades' do
    let(:course_users_array) do
      [
        ['4000123', 58, 58, 'F', 'F'],
        ['4000309', 93.75, 93.75, 'A-', 'A-'],
        ['4000199', 81.25, 87.5, 'B-', 'B+']
      ].collect do |u|
        {
          'login_id' => u[0],
          'enrollments' => [
            {
              'type' => 'StudentEnrollment',
              'grades' => {
                'current_score' => u[1],
                'final_score' => u[2],
                'current_grade' => u[3],
                'final_grade' => u[4]
              }
            }
          ]
        }
      end
    end
    let(:course_users_response) {
      {
        statusCode: 200,
        body: course_users_array
      }
    }

    before do
      allow_any_instance_of(Canvas::CourseUsers).to receive(:course_users).and_return course_users_response
      subject.background_job_initialize
    end
    it 'returns canvas course student grades' do
      result = subject.canvas_course_student_grades
      expect(result).to be_an_instance_of Array
      expect(result.count).to eq 3

      expect(result[0][:sis_login_id]).to eq '4000123'
      expect(result[0][:final_grade]).to eq 'F'
      expect(result[0][:current_grade]).to eq 'F'

      expect(result[1][:sis_login_id]).to eq '4000309'
      expect(result[1][:final_grade]).to eq 'A-'
      expect(result[1][:current_grade]).to eq 'A-'

      expect(result[2][:sis_login_id]).to eq '4000199'
      expect(result[2][:final_grade]).to eq 'B+'
      expect(result[2][:current_grade]).to eq 'B-'
    end

    it 'should not source data from cache' do
      expect(Canvas::CourseUsers).to_not receive :fetch_from_cache
      subject.canvas_course_student_grades
    end

    it 'should not specify forced cache write by default' do
      expect(CanvasLti::Egrades).to_not receive(:fetch_from_cache).with("course-students-#{canvas_course_id}", true)
      subject.canvas_course_student_grades
    end

    it 'should specify forced cache write when specified' do
      expect(CanvasLti::Egrades).to receive(:fetch_from_cache).with("course-students-#{canvas_course_id}", true)
      subject.canvas_course_student_grades true
    end
  end

  context 'when extracting student grades from enrollments' do
    let(:student_enrollment) do
      {
        'type' => 'StudentEnrollment',
        'role' => 'StudentEnrollment',
        'grades' => {
          'current_score' => 96.5,
          'final_score' => 95.0,
          'current_grade' => 'A+',
          'final_grade' => 'A'
        }
      }
    end
    let(:waitlist_student_enrollment) {
      student_enrollment.merge({
          'role' => 'Waitlist Student'
        })
    }
    let(:ta_enrollment) {
      {
        'type' => 'TaEnrollment',
        'role' => 'TaEnrollment'
      }
    }
    it 'returns empty grade hash when enrollments are empty' do
      result = subject.student_grade []
      expect(result[:current_score]).to eq nil
      expect(result[:current_grade]).to eq nil
      expect(result[:final_score]).to eq nil
      expect(result[:final_grade]).to eq nil
    end

    it 'returns empty grade when no student enrollments with grade are present' do
      waitlist_student_enrollment.delete 'grades'
      result = subject.student_grade [ta_enrollment, waitlist_student_enrollment]
      expect(result[:current_score]).to eq nil
      expect(result[:current_grade]).to eq nil
      expect(result[:final_score]).to eq nil
      expect(result[:final_grade]).to eq nil
    end

    it 'returns blank grade score when not present' do
      student_enrollment['grades'].delete 'current_score'
      student_enrollment['grades'].delete 'final_score'
      result = subject.student_grade [student_enrollment]
      expect(result[:current_score]).to eq nil
      expect(result[:current_grade]).to eq 'A+'
      expect(result[:final_score]).to eq nil
      expect(result[:final_grade]).to eq 'A'
    end

    it 'returns blank letter grade when not present' do
      student_enrollment['grades'].delete 'current_grade'
      student_enrollment['grades'].delete 'final_grade'
      result = subject.student_grade [student_enrollment]
      expect(result[:current_score]).to eq 96.5
      expect(result[:current_grade]).to eq nil
      expect(result[:final_score]).to eq 95.0
      expect(result[:final_grade]).to eq nil
    end

    it 'returns grade when student enrollment is present' do
      result = subject.student_grade [ta_enrollment, waitlist_student_enrollment, student_enrollment]
      expect(result[:current_score]).to eq 96.5
      expect(result[:current_grade]).to eq 'A+'
      expect(result[:final_score]).to eq 95.0
      expect(result[:final_grade]).to eq 'A'
    end
  end

  context 'when providing official sections' do
    let(:sections) do
      [
        {
          'course_title' => 'General Biology Lecture',
          'course_title_short' => 'GENERAL BIOLOGY LEC',
          'dept_name' => 'BIOLOGY',
          'catalog_id' => '1A',
          'term_yr' => '2017',
          'term_cd' => 'B',
          'course_cntl_num' => '13234',
          'primary_secondary_cd' => 'P',
          'section_num' => '001',
          'instruction_format' => 'LEC',
          'catalog_root' => '1',
          'catalog_prefix' => nil,
          'catalog_suffix_1' => 'A',
          'catalog_suffix_2' => nil
        },
        {
          'course_title' => 'General Biology Lecture',
          'course_title_short' => 'GENERAL BIOLOGY LEC',
          'dept_name' => 'BIOLOGY',
          'catalog_id' => '1A',
          'term_yr' => '2017',
          'term_cd' => 'B',
          'course_cntl_num' => '13235',
          'primary_secondary_cd' => 'P',
          'section_num' => '002',
          'instruction_format' => 'LEC',
          'catalog_root' => '1',
          'catalog_prefix' => nil,
          'catalog_suffix_1' => 'A',
          'catalog_suffix_2' => nil
        },
        # Secondary section
        {
          'course_title' => 'General Biology Discussion',
          'course_title_short' => 'GENERAL BIOLOGY DIS',
          'dept_name' => 'BIOLOGY',
          'catalog_id' => '1A',
          'term_yr' => '2017',
          'term_cd' => 'B',
          'course_cntl_num' => '13237',
          # primaryAssociatedSectionId: 13234
          'primary_secondary_cd' => 'S',
          'section_num' => '301',
          'instruction_format' => 'DIS',
          'catalog_root' => '1',
          'catalog_prefix' => nil,
          'catalog_suffix_1' => 'A',
          'catalog_suffix_2' => nil
        },
        # Below is an apparent DUPLICATE of the secondary section above. In the real world, our result-set might have
        # duplicate section ids. If the course has multiple primary sections (as above) then you might find a secondary
        # section with more than one parent; see column "primaryAssociatedSectionId" in SISEDO.CLASSSECTIONV00_VW.. That
        # might be useful info in other scenarios but the eGrades feature must filter out duplicates. This spec verifies
        # de-duplication logic.
        {
          'course_title' => 'General Biology Discussion',
          'course_title_short' => 'GENERAL BIOLOGY DIS',
          'dept_name' => 'BIOLOGY',
          'catalog_id' => '1A',
          'term_yr' => '2017',
          'term_cd' => 'B',
          'course_cntl_num' => '13237',
          # primaryAssociatedSectionId: 13235
          'primary_secondary_cd' => 'S',
          'section_num' => '301',
          'instruction_format' => 'DIS',
          'catalog_root' => '1',
          'catalog_prefix' => nil,
          'catalog_suffix_1' => 'A',
          'catalog_suffix_2' => nil
        }
      ]
    end

    before do
      allow_any_instance_of(CanvasLti::OfficialCourse).to receive(:official_section_identifiers).and_return section_identifiers
      allow(CanvasLti::SisAdapter).to receive(:get_sections_by_ids).with(%w(13234 13235 13237), '2017', 'B').and_return sections
    end
    context 'when official sections are not identified in course site' do
      let(:section_identifiers) { [] }
      it 'returns empty array' do
        expect(subject.official_sections).to eq []
      end
    end
    context 'when official sections are identified in course site' do
      let(:section_identifiers) {
        [
          {
            term_yr: '2017',
            term_cd: 'B',
            ccn: '13234'
          },
          {
            term_yr: '2017',
            term_cd: 'B',
            ccn: '13235'
          },
          {
            term_yr: '2017',
            term_cd: 'B',
            ccn: '13237'
          }
        ]
      }

      it 'provides array of filtered section hashes' do
        result = subject.official_sections
        expect(result.count).to eq 3
        # Primary
        biology_lec_001 = result[0]
        expect(biology_lec_001['course_cntl_num']).to eq '13234'
        expect(biology_lec_001['section_num']).to eq '001'
        expect(biology_lec_001['instruction_format']).to eq 'LEC'
        expect(biology_lec_001['primary_secondary_cd']).to eq 'P'
        # Primary
        biology_lec_002 = result[1]
        expect(biology_lec_002['course_cntl_num']).to eq '13235'
        expect(biology_lec_002['section_num']).to eq '002'
        expect(biology_lec_002['instruction_format']).to eq 'LEC'
        expect(biology_lec_002['primary_secondary_cd']).to eq 'P'
        # Secondary
        biology_dis_301 = result[2]
        expect(biology_dis_301['course_cntl_num']).to eq '13237'
        expect(biology_dis_301['section_num']).to eq '301'
        expect(biology_dis_301['instruction_format']).to eq 'DIS'
        expect(biology_dis_301['primary_secondary_cd']).to eq 'S'

        filtered_out_keys = %w(course_title course_title_short catalog_root catalog_prefix catalog_suffix_1 catalog_suffix_2)
        filtered_out_keys.each do |filtered_out_key|
          result.each do |section|
            expect(section).to_not include filtered_out_key
          end
        end
      end

      it 'filters out rows with duplicate section ids' do
        result = subject.official_sections
        expect(result.count).to eq 3
        expect(result[0]['display_name']).to eq 'BIOLOGY 1A LEC 001'
        expect(result[1]['display_name']).to eq 'BIOLOGY 1A LEC 002'
        expect(result[2]['display_name']).to eq 'BIOLOGY 1A DIS 301'
      end
    end
  end

  context 'when providing course states for grade export validation' do
    let(:official_course_sections) do
      [
        {
          'dept_name' => 'BIOLOGY',
          'catalog_id' => '1A',
          'term_yr' => '2017',
          'term_cd' => 'B',
          'course_cntl_num' => '13234',
          'primary_secondary_cd' => 'P',
          'section_num' => '001',
          'instruction_format' => 'LEC'
        },
        {
          'dept_name' => 'BIOLOGY',
          'catalog_id' => '1A',
          'term_yr' => '2017',
          'term_cd' => 'B',
          'course_cntl_num' => '13235',
          'primary_secondary_cd' => 'P',
          'section_num' => '002',
          'instruction_format' => 'LEC'
        },
        {
          'dept_name' => 'BIOLOGY',
          'catalog_id' => '1A',
          'term_yr' => '2017',
          'term_cd' => 'B',
          'course_cntl_num' => '13237',
          'primary_secondary_cd' => 'S',
          'section_num' => '301',
          'instruction_format' => 'DIS'
        },
      ]
    end
    let(:course_settings) do
      {
        statusCode: 200,
        body: {
          'grading_standard_enabled' => true,
          'grading_standard_id' => 0
        }
      }
    end
    let(:grade_types) {
      {
        number_grades_present: true,
        letter_grades_present: false
      }
    }
    let(:section_terms) {
      [
        {
          term_cd: 'B',
          term_yr: '2017'
        },
        {
          term_cd: 'C',
          term_yr: '2017'
        }
      ]
    }
    before do
      allow_any_instance_of(Canvas::CourseSettings).to receive(:settings).and_return course_settings
      allow_any_instance_of(CanvasLti::OfficialCourse).to receive(:section_terms).and_return section_terms
      allow(subject).to receive(:official_sections).and_return official_course_sections
      allow(subject).to receive(:grade_types_present).and_return grade_types
    end

    it 'provides official course sections' do
      result = subject.export_options
      official_sections = result[:officialSections]
      expect(official_sections.count).to eq 3
      expect(official_sections[0]['course_cntl_num']).to eq '13234'
      expect(official_sections[1]['course_cntl_num']).to eq '13235'
      expect(official_sections[2]['course_cntl_num']).to eq '13237'
    end

    it 'provides grading standard enabled boolean' do
      export_options = subject.export_options
      expect(export_options[:gradingStandardEnabled]).to eq true
    end

    it 'provides official section terms existing within course' do
      export_options = subject.export_options
      section_terms = export_options[:sectionTerms]
      expect(section_terms.count).to eq 2
      expect(section_terms[0][:term_cd]).to eq 'B'
      expect(section_terms[0][:term_yr]).to eq '2017'
      expect(section_terms[1][:term_cd]).to eq 'C'
      expect(section_terms[1][:term_yr]).to eq '2017'
    end
  end
end
