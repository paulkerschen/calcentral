shared_examples 'Canvas data refresh' do |import_type|

  let(:today) { Time.now.strftime '%F' }
  before do
    allow(Canvas::Terms).to receive(:current_sis_term_ids).and_return current_sis_term_ids
  end

  context 'with multiple terms' do
    before do
      allow(Settings.canvas_proxy).to receive(:import_zipped_csvs).and_return false
    end
    let(:current_sis_term_ids) { ['TERM:2013-D', 'TERM:2014-B'] }
    it 'establishes the csv import files' do
      expect(subject.users_csv_filename).to match Regexp.new("tmp/canvas/canvas-#{today}_[0-9]{6}-users-#{import_type}.csv")
      expect(subject.enrollment_term_csvs['TERM:2013-D']).to match Regexp.new("tmp/canvas/canvas-#{today}_[0-9]{6}-TERM_2013-D-enrollments-#{import_type}.csv")
      expect(subject.enrollment_term_csvs['TERM:2014-B']).to match Regexp.new("tmp/canvas/canvas-#{today}_[0-9]{6}-TERM_2014-B-enrollments-#{import_type}.csv")
    end
    it 'makes calls to each step of refresh in proper order' do
      expect(subject).to receive(:generate_csv_files).ordered.and_return true
      expect(subject).to receive(:import_single_csv_files).ordered.and_return true
      canvas_sync = double('canvas_synchronization')
      expect(CanvasCsv::Synchronization).to receive(:get).and_return(canvas_sync)
      expect(canvas_sync).to receive(:update).and_return(true)
      subject.run
    end

    context 'with zipped CSVs' do
      before do
        allow(Settings.canvas_proxy).to receive(:import_zipped_csvs).and_return true
      end
      it 'makes calls to each step of refresh in proper order' do
        expect(subject).to receive(:generate_csv_files).ordered.and_return true
        expect(subject).to receive(:import_zipped_csv_files).ordered.and_return true
        canvas_sync = double('canvas_synchronization')
        expect(CanvasCsv::Synchronization).to receive(:get).and_return(canvas_sync)
        expect(canvas_sync).to receive(:update).and_return(true)
        subject.run
      end
    end
  end

  describe 'enrollments_import_safe?' do
    let(:current_sis_term_ids) { ['TERM:2018-D'] }
    before do
      allow(Settings.canvas_proxy).to receive(:max_deleted_enrollments).and_return max_deleted
      subject.instance_eval do
        @enrollment_term_csvs = {'TERM:2018-D' => 'fixtures/csv/Canvas_sis_import_enrollments_all.csv'}
      end
    end
    describe 'above the threshold' do
      let(:max_deleted) { 3 }
      it 'warns us' do
        expect(subject.enrollments_import_safe?).to be_falsey
      end
    end
    describe 'below the threshold' do
      let(:max_deleted) { 4 }
      it 'does not warn' do
        expect(subject.enrollments_import_safe?).to be_truthy
      end
    end
  end
end


shared_context '2014-D Canvas sections report' do
  let(:current_sis_term_ids) { ['TERM:2014-D'] }
  let(:sections_report_csv_header_string) { 'canvas_section_id,section_id,canvas_course_id,course_id,name,status,start_date,end_date,canvas_account_id,account_id' }
  let(:sections_report_csv_string) do
    [
      sections_report_csv_header_string,
      '20,SEC:2014-D-25123,24,CRS:COMPSCI-9D-2014-D,COMPSCI 9D SLF 001,active,,,36,ACCT:COMPSCI',
      '19,SEC:2014-D-25124,24,CRS:COMPSCI-9D-2014-D,COMPSCI 9D SLF 002,active,,,36,ACCT:COMPSCI',
      '21,SEC:2014-D-25125,24,,COMPSCI 9D SLF 003,active,,,36,ACCT:COMPSCI',
      '22,,24,CRS:COMPSCI-9D-2014-D,COMPSCI 9D SLF 003,active,,,36,ACCT:COMPSCI',
    ].join("\n")
  end
  let(:sections_report_csv) { CSV.parse(sections_report_csv_string, :headers => :first_row) }
  let(:empty_sections_report_csv) { CSV.parse(sections_report_csv_header_string + "\n", :headers => :first_row) }
  let(:cached_enrollments_provider) { CanvasCsv::TermEnrollments.new }

  let(:users_csv) { subject.instance_eval { make_users_csv(@users_csv_filename) } }
  let(:term) { subject.instance_eval { enrollment_term_csvs.keys[0] } }
  let(:enrollments_csv) { subject.instance_eval { enrollment_term_csvs.values[0] } }
end


describe CanvasCsv::RefreshCampusDataAll do
  subject { CanvasCsv::RefreshCampusDataAll.new }

  include_examples 'Canvas data refresh', 'all'

  describe '#refresh_existing_term_sections' do
    include_context '2014-D Canvas sections report'

    context 'when canvas sections csv is present' do
      before { allow_any_instance_of(Canvas::Report::Sections).to receive(:get_csv).and_return(sections_report_csv) }
      it 'passes only sections with course_id and section_id to site membership maintainer process for each course' do
        expected_course_id = 'CRS:COMPSCI-9D-2014-D'
        expected_sis_section_ids = ['SEC:2014-D-25123', 'SEC:2014-D-25124']
        known_users, sis_user_id_changes = subject.instance_eval do
          @known_users = {}
          @sis_user_id_changes = { 'sis_login_id:7978' => {'old_id' => 'UID:7978', 'new_id' => '2018903'} }
          [@known_users, @sis_user_id_changes]
        end
        expect(CanvasCsv::SiteMembershipsMaintainer).to receive(:process).with(expected_course_id, expected_sis_section_ids, enrollments_csv, users_csv, known_users, cached_enrollments_provider, sis_user_id_changes).once
        subject.refresh_existing_term_sections(term, enrollments_csv, users_csv, cached_enrollments_provider)
      end
    end

    context 'when canvas sections csv is empty' do
      before { allow_any_instance_of(Canvas::Report::Sections).to receive(:get_csv).and_return csv }
      context 'empty' do
        let(:csv) { empty_sections_report_csv }
        it 'does not perform any processing' do
          expect(CanvasCsv::SiteMembershipsMaintainer).to_not receive(:process)
          expect(CanvasCsv::Synchronization).to_not receive(:get)
          subject.refresh_existing_term_sections(term, enrollments_csv, users_csv, cached_enrollments_provider)
        end
      end
      context 'nil' do
        let(:csv) { nil }
        it 'does not perform any processing' do
          expect(CanvasCsv::SiteMembershipsMaintainer).to_not receive(:process)
          expect(CanvasCsv::Synchronization).to_not receive(:get)
          subject.refresh_existing_term_sections(term, enrollments_csv, users_csv, cached_enrollments_provider)
        end
      end
    end
  end

  context 'with multiple terms' do
    let(:current_sis_term_ids) { ['TERM:2013-D', 'TERM:2014-B'] }
    before do
      allow(Settings.canvas_proxy).to receive(:import_zipped_csvs).and_return false
    end
    it 'should send call to populate incremental update csv for users and enrollments' do
      CanvasCsv::MaintainUsers.any_instance.should_receive(:refresh_existing_user_accounts).once.and_return nil
      expect_any_instance_of(CanvasCsv::RefreshCampusDataAll).to receive(:refresh_existing_term_sections).twice.and_return nil
      subject.generate_csv_files
    end
  end

  describe 'term-specific work' do
    let(:current_sis_term_ids) { ['TERM:2014-B'] }
    let(:ccn) { random_id }
    let(:canvas_term_sections_csv_string) do
      [
        'canvas_section_id,section_id,canvas_course_id,course_id,name,status,start_date,end_date,canvas_account_id,account_id',
        "#{ccn}2,SEC:2014-B-2#{ccn},#{random_id},CRS:#{ccn},DIS 101,active,,,105300,ACCT:LAW",
        "#{random_id},,#{random_id},CRS:#{ccn},INFORMAL 2,active,,,105300,ACCT:EDUC",
        "#{random_id},SEC:2014-B-#{random_id},#{random_id},,LAB 201,active,,,105300,ACCT:EDUC",
        "#{ccn}1,SEC:2014-B-1#{ccn},#{random_id},CRS:#{ccn},DIS 102,active,,,105300,ACCT:LAW"
      ].join("\n")
    end
    let(:canvas_term_sections_csv_table) { CSV.parse(canvas_term_sections_csv_string, {headers: true}) }
    before do
      allow_any_instance_of(CanvasCsv::MaintainUsers).to receive(:refresh_existing_user_accounts)
      allow_any_instance_of(Canvas::Report::Sections).to receive(:get_csv).and_return(canvas_term_sections_csv_table)
    end
    it 'passes well constructed parameters to the memberships maintainer' do
      expect(CanvasCsv::SiteMembershipsMaintainer).to receive(:new) do |course_id, section_ids, enrollments_csv, users_csv, known_users, options|
        expect(course_id).to eq "CRS:#{ccn}"
        expect(section_ids.size).to eq 2
        expect(section_ids[0]).to eq "SEC:2014-B-2#{ccn}"
        expect(section_ids[1]).to eq "SEC:2014-B-1#{ccn}"
        expect(known_users).to eq({})
        expect(options[:batch_mode]).to be_falsey
        expect(options[:cached_enrollments_provider]).to be_an_instance_of CanvasCsv::TermEnrollments
        double(refresh_sections_in_course: nil)
      end
      subject.generate_csv_files
    end
  end
end


describe CanvasCsv::RefreshCampusDataRecent do
  subject { CanvasCsv::RefreshCampusDataRecent.new }

  include_examples 'Canvas data refresh', 'recent'

  before do
    Dir.glob("#{Settings.canvas_proxy.export_directory}/*.csv").each { |f| File.delete f }

    allow(CanvasCsv::Synchronization).to receive(:get).and_return double(
      last_enrollment_sync: 1.weeks.ago.utc,
      last_guest_user_sync: 1.weeks.ago.utc,
      last_instructor_sync: 1.weeks.ago.utc,
      latest_term_enrollment_csv_set: 1.weeks.ago.utc
    )

    allow(EdoOracle::Bcourses).to receive(:get_recent_instructor_updates).and_return [
      {
        'section_id' => '25122',
        'term_id' => '2148',
        'ldap_uid' => '67890',
        'sis_id' => '678912345',
        'role_code' => 'PI',
        'primary' => false,
        'last_updated' => 1.day.ago
      },
      {
        'section_id' => '25123',
        'term_id' => '2148',
        'ldap_uid' => '67890',
        'sis_id' => '678912345',
        'role_code' => 'PI',
        'primary' => true,
        'last_updated' => 1.day.ago
      },
    ]

    allow(EdoOracle::Bcourses).to receive(:get_recent_enrollment_updates).and_return [
      {
        'section_id' => '12345',
        'term_id' => '2142',
        'ldap_uid' => '12345',
        'sis_id' => '1234567',
        'role_code' => 'PI',
        'enroll_status' => 'E',
        'course_career' => 'UGRD',
        'last_updated' => 1.day.ago
      },
      {
        'section_id' => '25123',
        'term_id' => '2148',
        'ldap_uid' => '12345',
        'sis_id' => '1234567',
        'enroll_status' => 'E',
        'course_career' => 'UGRD',
        'last_updated' => 1.day.ago
      },
      {
        'section_id' => '25124',
        'term_id' => '2148',
        'ldap_uid' => '12345',
        'sis_id' => '1234567',
        'enroll_status' => 'E',
        'course_career' => 'UGRD',
        'last_updated' => 1.day.ago
      },
    ]
  end

  describe '#refresh_term_enrollments' do
    include_context '2014-D Canvas sections report'

    let(:term_enrollments_csv_filepath) do
      provider = CanvasCsv::TermEnrollments.new
      CanvasCsv::TermEnrollments.new.enrollment_csv_filepath(provider.latest_term_enrollment_set_date, current_sis_term_ids.first)
    end

    before do
      export_csv = CanvasCsv::TermEnrollments.new.make_enrollment_export_csv(term_enrollments_csv_filepath)
      export_csv.close
    end

    after do
      delete_files_if_exists([term_enrollments_csv_filepath])
    end

    context 'when canvas sections csv is present' do
      let(:maintainer) do
        CanvasCsv::SiteMembershipsMaintainer.new('Dummy course ID', ['Dummy section ID'], enrollments_csv, users_csv, {})
      end
      before do
        expect(CanvasCsv::SiteMembershipsMaintainer).to receive(:new).at_least(:once).and_return(maintainer)
        allow_any_instance_of(Canvas::Report::Sections).to receive(:get_csv).and_return(sections_report_csv)
      end

      it 'calls membership maintainer where SISEDO updates overlap with sections csv' do
        expect(maintainer).to receive(:update_section_enrollment_from_campus)
          .with('TeacherEnrollment', 'SEC:2014-D-25123', '67890', {'67890' => []})
        expect(maintainer).to receive(:update_section_enrollment_from_campus)
          .with('StudentEnrollment', 'SEC:2014-D-25123', '12345', {'12345' => []})
        expect(maintainer).to receive(:update_section_enrollment_from_campus)
          .with('StudentEnrollment', 'SEC:2014-D-25124', '12345', {'12345' => []})
        subject.generate_csv_files
      end
    end

    context 'when canvas sections csv is empty' do
      before { allow_any_instance_of(Canvas::Report::Sections).to receive(:get_csv).and_return csv }
      context 'empty' do
        let(:csv) { empty_sections_report_csv }
        it 'does not perform any processing' do
          expect(CanvasCsv::SiteMembershipsMaintainer).to_not receive(:update_section_enrollment_from_campus)
          subject.generate_csv_files
        end
      end
      context 'nil' do
        let(:csv) { nil }
        it 'does not perform any processing' do
          expect(CanvasCsv::SiteMembershipsMaintainer).to_not receive(:update_section_enrollment_from_campus)
          subject.generate_csv_files
        end
      end
    end
  end

  context 'with multiple terms' do
    let(:current_sis_term_ids) { ['TERM:2014-B', 'TERM:2014-D'] }
    before do
      allow(Settings.canvas_proxy).to receive(:import_zipped_csvs).and_return false
    end
    it 'should send call to populate incremental update csv for users and enrollments' do
      expect_any_instance_of(CanvasCsv::MaintainUsers).to receive(:refresh_existing_user_accounts).once.and_return nil
      expect_any_instance_of(CanvasCsv::RefreshCampusDataRecent).to receive(:refresh_term_enrollments).twice.and_return nil
      subject.generate_csv_files
    end
  end
end

describe CanvasCsv::RefreshCampusDataAccounts do
  subject { CanvasCsv::RefreshCampusDataAccounts.new }
  before do
    allow(Settings.canvas_proxy).to receive(:import_zipped_csvs).and_return true
  end
  it 'only refreshes existing user accounts and leaves memberships alone' do
    expect_any_instance_of(CanvasCsv::MaintainUsers).to receive(:refresh_existing_user_accounts).once.and_return nil
    expect(subject).to receive(:refresh_existing_term_sections).never
    expect(subject).to receive(:csv_count).twice.and_return 1
    expect(subject).to receive(:zip_flattened) do |files, name|
      expect(files.length).to eq 2
    end
    expect_any_instance_of(Canvas::SisImport).to receive(:import_zipped).once.and_return true
    expect(CanvasCsv::Synchronization).to_not receive(:get)
    subject.run
  end
  context 'using APIs to change SIS IDs' do
    before { allow(Settings.canvas_proxy).to receive(:import_zipped_csvs).and_return false }
    it 'does not import SIS IDs CSV' do
      expect_any_instance_of(Canvas::SisImport).to receive(:import_users).once.and_return true
      expect_any_instance_of(Canvas::SisImport).to receive(:import_all_term_enrollments).never
      expect_any_instance_of(Canvas::SisImport).to receive(:import_sis_ids).never
      subject.run
    end
  end
end
