module GoogleApps
  class Authorization
    include ClassLogger

    def initialize(uid, app_id, request=nil, client_redirect_uri=nil)
      @uid = uid
      @request = request
      @client_redirect_uri = client_redirect_uri

      @app_id = app_id
      settings = GoogleApps::CredentialStore.settings_of @app_id
      @client_id = settings[:client_id]
      @client_secret = settings[:client_secret]
      @scope = settings[:scope]
    end

    def get_authorization
      credentials = User::Oauth2Data.get(@uid, @app_id)
      Google::Auth::UserRefreshCredentials.new(
        client_id:     @client_id,
        client_secret: @client_secret,
        scope:         @scope,
        access_token:  credentials[:access_token],
        refresh_token: credentials[:refresh_token],
        expires_at:    credentials[:expiration_time]
      )
    end

    def oauth2_refresh_tokens_url(params={})
      expire
      return_url = params['final_redirect'] || '/'
      authorization_url = get_authorizer.get_authorization_url(login_hint: @uid, request: @request, redirect_to: return_url)
      logger.debug "Initiating OAuth2 authorization for user #{@uid} via #{authorization_url}"
      authorization_url
    end

    def oauth2_process_callback
      logger.debug "Handling Google authorization callback for user #{@uid}"
      credentials_and_target_url = get_authorizer.handle_auth_callback(@uid, @request)
      expire
      return credentials_and_target_url.to_a[1] || '/'
    end

    def oauth2_revoke_authorization
      logger.warn "Deleting Google OAuth2 tokens of user #{@uid} (app_id: #{@app_id}) per user request"
      authorization = get_authorization
      authorization.revoke!
      User::Oauth2Data.remove(@uid, @app_id)
      expire
    end

    private

    def get_authorizer
      client_id = Google::Auth::ClientId.new(@client_id, @client_secret)
      credential_store = GoogleApps::CredentialStore.new(@app_id)
      Google::Auth::WebUserAuthorizer.new(client_id, @scope, credential_store, @client_redirect_uri)
    end

    def expire
      Cache::UserCacheExpiry.notify @uid
    end
  end
end
