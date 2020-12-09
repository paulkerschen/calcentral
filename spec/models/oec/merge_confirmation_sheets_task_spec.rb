describe Oec::MergeConfirmationSheetsTask do
  let(:term_code) { '2015-B' }
  let(:task) do
    Oec::MergeConfirmationSheetsTask.new(term_code: term_code, local_write: local_write, allow_past_term: true)
  end

  let(:fake_remote_drive) { double() }

  let(:departments_folder) { mock_google_drive_item }
  let(:last_import_folder) { mock_google_drive_item }
  let(:gws_folder) { mock_google_drive_item('Gender and Women\'s Studies') }
  let(:mcellbi_folder) { mock_google_drive_item('Molecular and Cell Biology') }

  def mock_sheet(filename)
    sheet_title = if filename.start_with? 'course'
                    'Courses'
                  else
                    filename
                  end
    sheet = {
      sheet: double(id: "#{sheet_title}_id", title: sheet_title),
      csv: File.read(Rails.root.join('fixtures', 'oec', "#{filename}.csv"))
    }
    @mock_sheets << sheet
    sheet
  end

  let(:gws_import) { mock_sheet 'import_GWS' }
  let(:gws_course_confirmation) { mock_sheet 'course_confirmations_GWS' }
  let(:mcellbi_import) { mock_sheet 'import_MCELLBI' }
  let(:mcellbi_course_confirmation) { mock_sheet 'course_confirmations_MCELLBI' }

  let(:gws_confirmation_spreadsheet) { mock_google_drive_item 'Gender and Women\'s Studies' }
  let(:mcellbi_confirmation_spreadsheet) { mock_google_drive_item 'Molecular and Cell Biology' }

  let(:merged_course_confirmation) { Oec::SisImportSheet.from_csv(File.read Rails.root.join('tmp', 'oec', 'Merged course confirmations.csv')) }

  let(:departments) { %w(SWOME IMMCB) }

  before(:each) do
    @mock_sheets = []

    allow(Oec::RemoteDrive).to receive(:new).and_return fake_remote_drive
    allow_any_instance_of(Oec::DepartmentMappings).to receive(:by_dept_code).and_return(departments.inject({}) { |hash, dept| hash[dept] = []; hash })
    allow_any_instance_of(Oec::DepartmentMappings).to receive(:participating_dept_names).and_return %w(GWS MCELLBI LGBT)
    allow(Settings.terms).to receive(:fake_now).and_return DateTime.parse('2015-03-09')

    allow(fake_remote_drive).to receive(:check_conflicts_and_create_folder).and_return mock_google_drive_item
    allow(fake_remote_drive).to receive(:find_nested).and_return mock_google_drive_item
    allow(fake_remote_drive).to receive(:find_first_matching_item).and_return mock_google_drive_item

    allow(fake_remote_drive).to receive(:find_folders).and_return [last_import_folder]
    allow(fake_remote_drive).to receive(:get_items_in_folder).and_return [gws_confirmation_spreadsheet, mcellbi_confirmation_spreadsheet]
    allow(fake_remote_drive).to receive(:spreadsheet_by_id).and_return(gws_confirmation_spreadsheet, mcellbi_confirmation_spreadsheet)
    allow(gws_confirmation_spreadsheet).to receive(:worksheets).and_return [gws_course_confirmation[:sheet]]
    allow(mcellbi_confirmation_spreadsheet).to receive(:worksheets).and_return [mcellbi_course_confirmation[:sheet]]

    allow(fake_remote_drive).to receive(:find_first_matching_item).with(Oec::Folder.confirmations, anything).and_return departments_folder
    allow(fake_remote_drive).to receive(:find_first_matching_item).with('Gender and Women\'s Studies', last_import_folder).and_return gws_import[:sheet]
    allow(fake_remote_drive).to receive(:find_first_matching_item).with('Molecular and Cell Biology', last_import_folder).and_return mcellbi_import[:sheet]

    @mock_sheets.each { |sheet| allow(fake_remote_drive).to receive(:export_csv).with(sheet[:sheet]).and_return sheet[:csv] }
  end

  after(:all) do
    FileUtils.rm_rf Rails.root.join('tmp', 'oec', 'Merged course confirmations.csv')
    Dir.glob(Rails.root.join 'tmp', 'oec', "*#{Oec::CreateConfirmationSheetsTask.name.demodulize.underscore}.log").each do |file|
      FileUtils.rm_rf file
    end
  end

  context 'expected API calls' do
    let(:local_write) { nil }

    it 'should upload merged confirmation sheets and log' do
      expect(fake_remote_drive).to receive(:check_conflicts_and_upload).with(kind_of(Oec::SisImportSheet), 'Merged course confirmations', Oec::Worksheet, anything, anything).and_return true
      expect(fake_remote_drive).to receive(:check_conflicts_and_upload).with(kind_of(Pathname), kind_of(String), 'text/plain', anything, anything).and_return true
      task.run
    end
  end

  context 'generated sheet structure' do
    let(:local_write) { 'Y' }

    let(:gws_course_confirmation_worksheet) { Oec::CourseConfirmation.from_csv gws_course_confirmation[:csv] }
    let(:mcellbi_course_confirmation_worksheet) { Oec::CourseConfirmation.from_csv mcellbi_course_confirmation[:csv] }
    let(:gws_sis_import) { Oec::SisImportSheet.from_csv gws_import[:csv] }
    let(:mcellbi_sis_import) { Oec::SisImportSheet.from_csv mcellbi_import[:csv] }

    before { task.run }

    it 'should produce a merged course confirmation' do
      expect(merged_course_confirmation.first).to_not be_empty
    end

    it 'should include courses marked for evaluation by all participating departments' do
      expect(merged_course_confirmation.select { |row| row['DEPT_FORM'] == 'GWS' }).to have(20).items
      expect(merged_course_confirmation.select { |row| row['DEPT_FORM'] == 'LGBT' }).to have(3).items
      expect(merged_course_confirmation.select { |row| row['DEPT_FORM'] == 'MCELLBI' }).to have(15).items
    end

    it 'should group cross-listings together' do
      cross_listed_names = merged_course_confirmation.map { |row| row['CROSS_LISTED_NAME'] }.compact.uniq
      cross_listed_names.each do |name|
        index_of_first_listing = merged_course_confirmation.find_index { |row| row['CROSS_LISTED_NAME'] == name }
        expect(merged_course_confirmation[index_of_first_listing + 1]['CROSS_LISTED_NAME']).to eq name
      end
    end

    it 'should overwrite SIS import data when confirmed course data includes column' do
      [gws_course_confirmation_worksheet, gws_sis_import, mcellbi_course_confirmation_worksheet, mcellbi_sis_import].each_slice(2) do |confirmation, sis_import|
        confirmation.each do |confirmation_row|
          merged_confirmation_row = merged_course_confirmation.find { |row| row['COURSE_ID'] == confirmation_row['COURSE_ID'] && row['LDAP_UID'] == confirmation_row['LDAP_UID'] }
          sis_import_row = sis_import.find { |row| row['COURSE_ID'] == confirmation_row['COURSE_ID'] && row['LDAP_UID'] == confirmation_row['LDAP_UID'] }
          merged_course_confirmation.headers.each do |header|
            if confirmation.headers.include? header
              expect(merged_confirmation_row[header]).to eq confirmation_row[header]
            else
              expect(merged_confirmation_row[header]).to eq sis_import_row[header]
            end
          end
        end
      end
    end

    context 'when a department filter is specified' do
      let(:departments) { %w(SWOME) }

      it 'should include courses marked for evaluation by filtered departments only' do
        expect(merged_course_confirmation.select { |row| row['DEPT_FORM'] == 'GWS' }).to have(20).items
        expect(merged_course_confirmation.select { |row| row['DEPT_FORM'] == 'LGBT' }).to have(3).items
        expect(merged_course_confirmation.select { |row| row['DEPT_FORM'] == 'MCELLBI' }).to have(0).items
      end
    end
  end

  context 'when course confirmation sheets include conflicting data' do
    let(:local_write) { 'Y' }
    before do
      gws_import[:csv].concat '2015-B-91111,2015-B-91111,GWS 165 LEC 001 MEIOSIS AND GENDER TROUBLE,Y,GWS/MCELLBI 165 LEC 001,GWS,165,LEC,001,P,100008,Instructor,Eight,instructor8@berkeley.edu,,,F,,1/20/2015,5/8/2015'
      mcellbi_import[:csv].concat '2015-B-91111,2015-B-91111,GWS 165 LEC 001 MEIOSIS AND GENDER TROUBLE,Y,GWS/MCELLBI 165 LEC 001,GWS,165,LEC,001,P,100008,Instructor,Eight,instructor8@berkeley.edu,,,F,,1/20/2015,5/8/2015'
      gws_course_confirmation[:csv].concat '2015-B-91111,GWS 165 LEC 001 MEIOSIS AND GENDER TROUBLE,Y,GWS/MCELLBI 165 LEC 001,100008,Instructor,Eight,instructor8@berkeley.edu,Y,GWS,F,,1/20/2015,5/8/2015'
      mcellbi_course_confirmation[:csv].concat '2015-B-91111,GWS 165 LEC 001 MEIOSIS AND GENDER TROUBLE,Y,GWS/MCELLBI 165 LEC 001,100008,Instructor,Eight,instructor8@berkeley.edu,Y,MCELLBI,F,,1/20/2015,5/8/2015'
    end

    it 'should record errors' do
      expect(Rails.logger).to receive(:warn).at_least(1).times
      task.run
      expect(task.errors['Merged course confirmations']['2015-B-91111-100008'].keys).to eq ["Conflicting values found under DEPT_FORM: 'GWS', 'MCELLBI'"]
    end

    it 'should include both rows in merged sheet' do
      task.run
      conflicting_rows = merged_course_confirmation.select { |row| row['COURSE_ID'] == '2015-B-91111' }
      expect(conflicting_rows).to have(2).items
      expect(conflicting_rows.map { |row| row['DEPT_FORM'] }).to match_array %w(GWS MCELLBI)
    end
  end

  context 'when confirmed course data cannot be matched to SIS import' do
    let(:local_write) { 'Y' }
    before do
      gws_course_confirmation[:csv].concat '2015-B-91111,GWS 165 LEC 001 MEIOSIS AND GENDER TROUBLE,Y,GWS/MCELLBI 165 LEC 001,100008,Instructor,Eight,instructor8@berkeley.edu,Y,GWS,F,,1/20/2015,5/8/2015'
    end

    it 'should record errors' do
      expect(Rails.logger).to receive(:warn).at_least(1).times
      task.run
      expect(task.errors['Merged course confirmations']['2015-B-91111-100008'].keys).to eq ['No SIS import row found matching confirmation row']
    end

    it 'should export a row with blank values for SIS data' do
      task.run
      rows_without_sis_data = merged_course_confirmation.select { |row| row['COURSE_ID'] == '2015-B-91111' }
      expect(rows_without_sis_data).to have(1).items
      %w(COURSE_ID_2 DEPT_NAME CATALOG_ID INSTRUCTION_FORMAT SECTION_NUM PRIMARY_SECONDARY_CD).each do |sis_column|
        expect(rows_without_sis_data.first[sis_column]).to be_blank
      end
    end

    it 'should fill in empty SIS_ID values' do
      expect(User::BasicAttributes).to receive(:attributes_for_uids).with(['100008']).and_return([{
        ldap_uid: '100008',
        student_id: '2345678',
        roles: {
          student: true,
          registered: true
        }
      }])
      task.run
      row_without_sis_data = merged_course_confirmation.find { |row| row['COURSE_ID'] == '2015-B-91111' }
      expect(row_without_sis_data['SIS_ID']).to eq '2345678'
    end
  end
end
