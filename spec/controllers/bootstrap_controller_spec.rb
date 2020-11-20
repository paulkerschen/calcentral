describe BootstrapController do
  let(:user_id) { random_id }

  context 'when previously authenticated by LTI' do
    before do
      session['user_id'] = user_id
      session['lti_authenticated_only'] = true
    end
    it 'should force campus authentication' do
      get :index
      hostname = request.env['HTTP_HOST']
      expect(response).to redirect_to '/auth/cas'
    end
  end

end
