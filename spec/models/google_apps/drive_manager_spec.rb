describe GoogleApps::DriveManager do

  subject(:drive) { GoogleApps::DriveManager.new(GoogleApps::CredentialStore::GOOGLE_APP_ID, random_id) }

  before do
    allow(User::Oauth2Data).to receive(:get).and_return({
      access_token: 'fake_access_token',
      refresh_token: 'fake_refresh_token',
      expiration_time: (DateTime.now + 2.hours).to_i
    })
  end

  context 'unauthorized' do
    before do
      expect(Google::Auth::UserRefreshCredentials).to receive(:new).once.and_return (credentials = double)
    end

    it 'should abort when OAuth2 tokens are not found' do
      expect{ drive.find_folders }.to raise_error Errors::ProxyError
    end
  end

  context 'authorized' do
    let(:drive_api) { double }
    before do
      allow(drive).to receive(:drive_api).and_return drive_api
    end

    context 'Google Drive operations' do
      context 'find items in folder' do
        let(:folder_name) { random_string(10) }
        let(:responses) {
          [
            double(files: [ double, double ], next_page_token: random_id),
            double(files: [ double, double ], next_page_token: random_id),
            double(files: [ double ], next_page_token: nil)
          ]
        }  
        before do
          responses.each { |r| expect(drive_api).to receive(:list_files).once.ordered.and_return r }
        end
        it 'should find items' do
          expect(drive.find_folders_by_name folder_name).to have(5).items
        end
      end
    end
  end

end
