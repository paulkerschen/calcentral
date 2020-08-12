class OecGoogleAuthController < ApplicationController
  include ClassLogger

  before_filter :authenticate
  before_filter :check_google_access
  before_action :authorize_oec_administration
  respond_to :json

  def authorize_oec_administration
    authorize current_user, :can_administer_oec?
  end

  def refresh_tokens
    url = google.refresh_oauth2_tokens_url params
    redirect_to url
  end

  def handle_callback
    google.process_callback(params, opts)
    final_redirect = params['state']
    url = final_redirect ? Base64.decode64(final_redirect) : url_for_path('/')
    redirect_to url
  end

  def current_scope
    render json: {
      currentScope: google.scope_granted
    }
  end

  def remove_authorization
    google.remove_user_authorization
    render nothing: true, status: 204
  end

  private

  def google
    @google ||= GoogleApps::Oauth2TokensGrant.new(user_id, app_id, client_redirect_uri)
  end

  def user_id
    opts[:uid]
  end

  def app_id
    GoogleApps::Proxy::OEC_APP_ID
  end

  def opts
    @opts ||= Settings.oec.google.marshal_dump
  end

  def client_redirect_uri
    url_for only_path: false, controller: 'oec_google_auth', action: 'handle_callback'
  end

end
