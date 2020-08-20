describe OecGoogleAuthController do

  let(:oec_user_id) { Settings.oec.google.uid }
  let(:settings) {
    {
      uid: oec_user_id,
      client_id: Settings.oec.google.client_id,
      client_secret: Settings.oec.google.client_secret,
      scope: Settings.oec.google.scope
    }
  }
  let(:session_user_id) { random_id }
  let(:can_administer_oec) { true }
  let(:app_id) { GoogleApps::CredentialStore::OEC_APP_ID }
  let(:params) { {} }

  before do
    session['user_id'] = session_user_id
    allow(Oec::Administrator).to receive(:is_admin?).with(session_user_id).and_return can_administer_oec
    allow(Settings.oec.google).to receive(:marshal_dump).and_return settings
  end

  describe 'Google transaction' do
    let(:google_url) { random_string 10 }
    let(:authorizer) {
      expect(Google::Auth::WebUserAuthorizer).to receive(:new).and_return (authorizer = double)
      authorizer
    }

    before do
      allow(GoogleApps::CredentialStore).to receive(:access_granted?).with(session_user_id).and_return true
    end

    describe '#refresh_tokens' do
      before do
        expect(authorizer).to receive(:get_authorization_url).and_return google_url
      end

      context 'user can refresh Google OAuth tokens' do
        let(:params) { {} }

        it 'should redirect to Google' do
          post :refresh_tokens, params
          expect(response).to have_http_status 302
        end
      end
    end

    describe '#process_callback' do
      context 'handle Google callback' do
        before do
          expect(authorizer).to receive(:handle_auth_callback)
        end
        it 'should record new client_id and client_secret' do
          post :handle_callback, params
          expect(response).to have_http_status 302
        end
      end
    end
  end

  context 'cannot administer OEC' do
    let(:can_administer_oec) { false }

    it 'should reject user as unauthorized' do
      post :refresh_tokens
      expect(response).to have_http_status 403
    end
  end

  context 'indirectly authenticated' do
    before do
      allow(GoogleApps::CredentialStore).to receive(:access_granted?).with(session_user_id).and_return true
      allow(Google::Auth::WebUserAuthorizer).to receive(:new).never
    end

    subject do
      post :refresh_tokens, params
    end

    context 'viewing as' do
      before do
        session[SessionKey.original_user_id] = random_id
      end
      it { is_expected.not_to have_http_status :success }
    end
    context 'LTI embedded' do
      before do
        session['lti_authenticated_only'] = true
      end
      it { is_expected.not_to have_http_status :success }
    end
  end
end
