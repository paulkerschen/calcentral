describe Oec::ValidationTask do
  let(:term_code) { '2015-B' }
  let(:task) { Oec::ValidationTask.new(term_code: term_code, local_write: 'Y', allow_past_term: true) }

  include_context 'OEC data validation'

  context 'valid fixture data' do
    it 'should pass validation' do
      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).with /Validation passed./
      task.run
    end
    context 'recognized COURSE_ID suffix' do
      let(:valid_row) { '2015-B-99999_MID,2015-B-99999_MID,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015' }
      it 'should pass validation' do
        merged_course_confirmations_csv.concat valid_row
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with /Validation passed./
        task.run
      end
    end
    context 'Explorance-unfriendly DEPT_NAME' do
      let(:valid_row) { '2015-B-56212,2015-B-56212,"A,RESEC 213 LEC 001 APPLIED ECONOMETRIC",,,"A,RESEC",213,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,A_RESEC,F,,01-26-2015,05-11-2015' }
      it 'should pass validation' do
        merged_course_confirmations_csv.concat valid_row
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with /Validation passed./
        task.run
      end
    end
  end

  shared_examples 'validation error logging' do
    it 'should log error' do
      merged_course_confirmations_csv.concat invalid_row
      allow(Rails.logger).to receive(:warn)
      expect(Rails.logger).to receive(:warn).with /Validation failed!/
      task.run
      expect(task.errors[sheet_name][key].keys.first).to eq expected_message
    end
  end

  shared_examples 'validation warning logging' do
    it 'should log warning' do
      merged_course_confirmations_csv.concat invalid_row
      allow(Rails.logger).to receive(:warn)
      expect(Rails.logger).to receive(:warn).with(/#{Regexp.quote expected_message}/)
      task.run
    end
  end

  context 'conflicting instructor data' do
    let(:invalid_row) { '2015-B-32960,2015-B-32960,GWS 103 LEC 001 IDENTITY ACROSS DIF,,,GWS,103,LEC,001,P,104033,UID:104033,BAD_FIRST_NAME,Ffff,ffff@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015' }
    let(:sheet_name) { 'instructors' }
    let(:key) { '104033' }
    let(:expected_message) { "Conflicting values found under FIRST_NAME: 'Flora', 'BAD_FIRST_NAME'" }
    include_examples 'validation error logging'
  end

  context 'conflicting course dates' do
    let(:invalid_row) { '2015-B-34818,2015-B-34818,LGBT 100 LEC 001 SPECIAL TOPICS,,,LGBT,100,LEC,001,P,77865,UID:77865,Doris,Dddd,dddd@berkeley.edu,23,Y,LGBT,F,Y,02-01-2015,05-01-2015' }
    let(:sheet_name) { 'courses' }
    let(:key) { '2015-B-34818' }
    let(:expected_message) { "Conflicting values found under END_DATE: '04-01-2015', '05-01-2015'" }
    include_examples 'validation error logging'
  end

  context 'courses sheet validations' do
    let(:sheet_name) { 'courses' }
    let(:key) { '2015-B-99999' }

    context 'invalid course id' do
      let(:invalid_row) { '2015-B-999991,2015-B-999991,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015' }
      let(:key) { '2015-B-999991' }
      let(:expected_message) { 'Invalid COURSE_ID 2015-B-999991' }
      include_examples 'validation error logging'
    end

    context 'non-matching COURSE_ID_2' do
      let(:invalid_row) { '2015-B-99999,2015-B-99998,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015' }
      let(:expected_message) { 'Non-matching COURSE_ID_2 2015-B-99998' }
      include_examples 'validation error logging'
    end

    context 'unrecognized COURSE_ID suffix' do
      let(:key) { '2015-B-99999_HUH' }
      let(:invalid_row) { '2015-B-99999_HUH,2015-B-99999_HUH,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015' }
      let(:expected_message) { 'Invalid COURSE_ID 2015-B-99999_HUH' }
      include_examples 'validation error logging'
    end

    context 'unexpected GSI evaluation type' do
      let(:key) { '2015-B-99999_GSI' }
      let(:invalid_row) { '2015-B-99999_GSI,2015-B-99999_GSI,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015' }
      let(:expected_message) { 'Unexpected for _GSI course: EVALUATION_TYPE F' }
      include_examples 'validation error logging'
    end

    context 'course ID in wrong term' do
      let(:invalid_row) { '2014-B-99999,2014-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015' }
      let(:key) { '2014-B-99999' }
      let(:expected_message) { 'Incorrect term code in COURSE_ID 2014-B-99999' }
      include_examples 'validation error logging'
    end

    context 'start and end date equal' do
      let(:invalid_row) { '2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,Y,03-11-2015,03-11-2015' }
      let(:key) { '2015-B-99999' }
      let(:expected_message) { 'START_DATE 03-11-2015 equal to END_DATE 03-11-2015' }
      include_examples 'validation error logging'
    end

    context 'end date before start date' do
      let(:invalid_row) { '2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,Y,03-26-2015,03-11-2015' }
      let(:key) { '2015-B-99999' }
      let(:expected_message) { 'START_DATE 03-26-2015 later than END_DATE 03-11-2015' }
      include_examples 'validation error logging'
    end

    context 'date not matching term code' do
      let(:invalid_row) { '2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,Y,01-26-2015,05-11-2016' }
      let(:key) { '2015-B-99999' }
      let(:expected_message) { 'END_DATE 05-11-2016 does not match term code 2015-B' }
      include_examples 'validation error logging'
    end

    context 'default dates for modular course' do
      let(:invalid_row) { '2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,Y,01-26-2015,05-11-2015' }
      let(:key) { '2015-B-99999' }
      let(:expected_message) { 'Default term dates 01-26-2015 to 05-11-2015 for modular course' }
      include_examples 'validation error logging'
    end

    context 'non-default dates for non-modular course' do
      let(:invalid_row) { '2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,02-26-2015,05-11-2015' }
      let(:key) { '2015-B-99999' }
      let(:expected_message) { 'Unexpected dates 02-26-2015 to 05-11-2015 for non-modular course' }
      include_examples 'validation error logging'
    end

    context 'evaluation type validation' do
      let(:invalid_row) { "2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,#{dept_form},#{evaluation_type},,01-26-2015,05-11-2015" }
      let(:key) { '2015-B-99999' }

      context 'LAW evaluation type for non-LAW course' do
        let(:dept_form) { 'GWS' }
        let(:evaluation_type) { '1A' }
        let(:expected_message) { 'Unexpected evaluation type: 1A in course 2015-B-99999' }
        include_examples 'validation warning logging'
      end

      context 'SPANISH evaluation type for non-SPANISH course' do
        let(:dept_form) { 'GWS' }
        let(:evaluation_type) { 'LANG' }
        let(:expected_message) { 'Unexpected evaluation type: LANG in course 2015-B-99999' }
        include_examples 'validation warning logging'
      end

      context 'generic evaluation type for SPANISH course' do
        let(:dept_form) { 'SPANISH' }
        let(:evaluation_type) { 'F' }
        let(:expected_message) { 'Unexpected evaluation type for SPANISH department form: F in course 2015-B-99999' }
        include_examples 'validation warning logging'
      end

      context 'generic evaluation type for LAW course' do
        let(:dept_form) { 'LAW' }
        let(:evaluation_type) { 'F' }
        let(:expected_message) { 'Unexpected evaluation type for LAW department form: F in course 2015-B-99999' }
        include_examples 'validation warning logging'
      end

      context 'wholly unexpected evaluation type' do
        let(:dept_form) { 'GWS' }
        let(:evaluation_type) { 'GAUNTLET' }
        let(:expected_message) { 'Unexpected evaluation type: GAUNTLET in course 2015-B-99999' }
        include_examples 'validation warning logging'
      end
    end

    context 'unexpected MODULAR_COURSE value' do
      let(:invalid_row) { '2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,F12,01-26-2015,05-11-2015' }
      let(:key) { '2015-B-99999' }
      let(:expected_message) { 'Unexpected MODULAR_COURSE value F12' }
      include_examples 'validation error logging'
    end

    context 'conflicting instructor data across cross-listings' do
      let(:invalid_row) { '2015-B-34821,2015-B-34821,LGBT C146A LEC 001 REP SEXUALITY/LIT,Y,GWS/LGBT C146A LEC 001,LGBT,C146A,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,LGBT,F,,01-26-2015,05-11-2015' }
      let(:key) { '2015-B-34821' }
      it 'should pass with warning' do
        merged_course_confirmations_csv.concat invalid_row
        task.run
        log_warnings = task.instance_variable_get(:@log)
        msg = 'Instructor list (155555, 942792) differs from instructor list (942792) of cross-listed course 2015-B-32984'
        expect(log_warnings.find {|m| m.include? msg}).to be_present
        expect(task.errors).to be_blank
      end
    end

    context 'DEPT_FORM specifies non-participating department' do
      before { allow_any_instance_of(Oec::DepartmentMappings).to receive(:participating_dept_names).and_return %w(BIOLOGY INTEGBI MCELLBI) }
      let(:row_with_new_dept) { '2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015' }
      let(:key) { '2015-B-99999' }
      it 'should pass with warning' do
        merged_course_confirmations_csv.concat row_with_new_dept
        allow(Rails.logger).to receive(:warn)
        expect(Rails.logger).to receive(:warn).with /DEPT_FORM GWS not found among participating departments/
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with /Validation passed./
        task.run
      end
    end
  end

  context 'instructors sheet validations' do
    let(:sheet_name) { 'instructors' }

    context 'invalid BLUE_ROLE' do
      let(:key) { '155555' }
      let(:invalid_row) { '2015-B-99999_GSI,2015-B-99999_GSI,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555,UID:155555,Zachary,Zzzz,zzzz@berkeley.edu,24,Y,GWS,F,,01-26-2015,05-11-2015' }
      let(:expected_message) { 'Invalid BLUE_ROLE 24' }
      include_examples 'validation error logging'
    end

    context 'non-numeric UID' do
      let(:key) { '155555Z' }
      let(:invalid_row) { '2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555Z,UID:155555Z,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015' }
      let(:expected_message) { 'Non-numeric LDAP_UID 155555Z' }
      include_examples 'validation error logging'
    end
  end

  context 'repeated errors' do
    before do
      merged_course_confirmations_csv.concat "2015-B-99999,2015-B-99999,GWS 150 LEC 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555Z,UID:155555Z,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015\n"
      merged_course_confirmations_csv.concat "2015-B-99999,2015-B-99999,GWS 150 DIS 001 VINDICATION OF RIGHTS,,,GWS,150,LEC,001,P,155555Z,UID:155555Z,Zachary,Zzzz,zzzz@berkeley.edu,23,Y,GWS,F,,01-26-2015,05-11-2015\n"
      expect(task).not_to receive :export_sheet
    end

    it 'should record a row count' do
      task.run
      expect(task.errors['instructors']['155555Z'].first).to eq ['Non-numeric LDAP_UID 155555Z', 2]
    end
  end

end
