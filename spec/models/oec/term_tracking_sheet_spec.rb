describe Oec::TermTrackingSheet do

  let(:fake_remote_drive) { double }
  let(:tracking_spreadsheet) { double(worksheets: [tracking_worksheet]) }
  let(:tracking_worksheet) { double(:[] => nil, :[]= => true, save: true) }

  let(:term_tracking_sheet) { described_class.new(fake_remote_drive, '2020-D') }

  before do
    allow(fake_remote_drive).to receive(:find_first_matching_item).and_return mock_google_drive_item
    allow(fake_remote_drive).to receive(:find_first_matching_item).with(term_tracking_sheet.name, anything)
      .and_return double(id: 'tracking_sheet_id')
    allow(fake_remote_drive).to receive(:spreadsheet_by_id).with('tracking_sheet_id').and_return tracking_spreadsheet
  end

  it 'knows its name' do
    expect(term_tracking_sheet.name).to eq 'Fall 2020 Course Evaluations Tracking Sheet'
  end

  it 'finds a worksheet' do
    expect(term_tracking_sheet.get_worksheet).to eq tracking_worksheet
  end

  context 'no Internal Status column' do
    before do
      allow(tracking_worksheet).to receive(:[]).with(2, 1).and_return 'Department'
      allow(tracking_worksheet).to receive(:[]).with(2, 2).and_return 'Irrelevant column'
      allow(tracking_worksheet).to receive(:[]).with(3, 1).and_return 'Classics'
      allow(tracking_worksheet).to receive(:[]).with(4, 1).and_return 'English'
      allow(tracking_worksheet).to receive(:[]).with(5, 1).and_return 'Molecular and Cell Biology'
    end

    it 'finds no departments ready to publish' do
      expect(term_tracking_sheet.departments_with_status('Ready to Publish')).to eq []
    end
  end

  context 'Internal Status column exists' do
    before do
      allow(tracking_worksheet).to receive(:[]).with(2, 1).and_return 'Department'
      allow(tracking_worksheet).to receive(:[]).with(2, 2).and_return 'Internal Status'
      allow(tracking_worksheet).to receive(:[]).with(3, 1).and_return 'Classics'
      allow(tracking_worksheet).to receive(:[]).with(4, 1).and_return 'English'
      allow(tracking_worksheet).to receive(:[]).with(5, 1).and_return 'Molecular and Cell Biology'

      allow(tracking_worksheet).to receive(:[]).with(3, 2).and_return 'Ready to Publish'
      allow(tracking_worksheet).to receive(:[]).with(4, 2).and_return 'Not ready'      
      allow(tracking_worksheet).to receive(:[]).with(5, 2).and_return 'Ready to Publish'
    end

    it 'finds departments ready to publish' do
      expect(term_tracking_sheet.departments_with_status('Ready to Publish')).to eq ['Classics', 'Molecular and Cell Biology']
    end
  end

end
