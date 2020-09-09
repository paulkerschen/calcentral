class OecGoogleAuthController < ApplicationController
  include ClassLogger

  before_action :authenticate
  before_action :check_google_access
  before_action :authorize_oec_administration
  respond_to :json

  def authorize_oec_administration
    authorize current_user, :can_administer_oec?
  end

  def refresh_tokens
    url = auth.oauth2_refresh_tokens_url params
    redirect_to url
  end

  def handle_callback
    redirect_to auth.oauth2_process_callback
  end

  def remove_authorization
    auth.oauth2_revoke_authorization
    head 204
  end

  private

  def auth
    @auth ||= GoogleApps::Authorization.new(Settings.oec.google.uid, GoogleApps::CredentialStore::OEC_APP_ID, request, client_redirect_uri)
  end

  def client_redirect_uri
    url_for only_path: false, controller: 'oec_google_auth', action: 'handle_callback'
  end

end
