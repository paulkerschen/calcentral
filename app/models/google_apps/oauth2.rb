require 'google/api_client'

module GoogleApps
  class Oauth2 < BaseProxy
    include ClassLogger

    def initialize(user_id, app_id, client_redirect_uri)
      @user_id = user_id
      @app_id = app_id
      @client_redirect_uri = client_redirect_uri
      super(GoogleApps::CredentialStore.config_of(@app_id))
    end

    def refresh_oauth2_tokens_url(params)
      expire
      settings = GoogleApps::CredentialStore.settings_of @app_id
      scope = settings[:scope]
      if (scope_override = params['scope']).present?
        additional_scope = scope_override.is_a?(Array) ? scope_override.join(' ') : scope_override
        scope += " #{additional_scope}"
      end
      opts = {
        scope: scope,
        final_redirect: params['final_redirect'] || '/',
        omit_domain_restriction: params['force_domain'].present? && params['force_domain'] == 'false'
      }
      client = get_client opts
      url = client.authorization_uri(approval_prompt: 'force').to_s
      logger.debug "Initiating OAuth2 authorization for user #{@user_id} via #{url}"
      url
    end

    def process_callback(params, opts={})
      logger.debug "Handling Google authorization callback for user #{@user_id}"
      if params['code'] && params['error'].blank?
        # Clone hash then remove :scope. Google will reject fetch_access_token! if :scope is present.
        modified_opts = opts.clone
        modified_opts.delete :scope
        client = get_client modified_opts
        client.code = params['code']
        client.fetch_access_token!
        logger.warn "Saving #{@app_id} access token for user #{@user_id}"
        credentials = {
          expiration_time: client.expires_in.blank? ? 0 : (client.issued_at.to_i + client.expires_in),
          access_token: client.access_token.to_s,
          refresh_token: client.refresh_token
        }
        store = GoogleApps::CredentialStore.new(@app_id, @user_id, @opts)
        store.write_credentials credentials
      else
        logger.warn "Deleting the Google OAuth2 tokens of user #{@user_id} (app_id: #{@app_id}) because callback reported an error: #{params['error']}"
        User::Oauth2Data.remove(@user_id, @app_id)
      end
      expire
    end

    def revoke_authorization
      logger.warn "Deleting Google OAuth2 tokens of user #{@user_id} (app_id: #{@app_id}) per user request"
      unless (access_token = get_access_token)
        logger.error "Nil access_token for #{@user_id}; revoking Google OAuth privileges is not possible."
        return false
      end
      response = get_response(
        'https://accounts.google.com/o/oauth2/revoke',
        query: {
          token: access_token
        },
        on_error: {
          rescue_status: :all
        }
      )
      if response.code == 200
        logger.warn "Successfully revoked Google access token for user #{@uid}"
      else
        logger.error "Got an error trying to revoke Google access token for user #{@uid}. Status: #{response.code} Body: #{response.body}"
      end
      User::Oauth2Data.remove(@user_id, @app_id)
      expire
    end

    private

    def expire
      Cache::UserCacheExpiry.notify @user_id
    end

    def get_client(opts={})
      google_client = Google::APIClient.new(options={
        application_name: 'CalCentral',
        application_version: 'v1',
        retries: 3
      })
      client = google_client.authorization
      unless opts[:omit_domain_restriction]
        client.authorization_uri = URI 'https://accounts.google.com/o/oauth2/auth?hd=berkeley.edu'
      end
      settings = GoogleApps::CredentialStore.settings_of @app_id
      client.client_id = settings[:client_id]
      client.client_secret = settings[:client_secret]
      client.redirect_uri = @client_redirect_uri
      final_redirect = opts[:final_redirect] || ''
      client.state = Base64.encode64 final_redirect
      if opts[:scope]
        client.scope = opts[:scope]
        # Do not lose any manually added authorizations when refreshing the more generic list.
        client.update!(
          additional_parameters: {
            'include_granted_scopes' => 'true'
          }
        )
      end
      client
    end

    def get_access_token
      authorization = get_authorization(@app_id, user_id)
      authorization.access_token
    end

    def get_authorization(app_id, uid)
      if @fake
        GoogleApps::Client.new_fake_auth app_id
      else
        token_settings = User::Oauth2Data.get(uid, app_id)
        GoogleApps::Client.new_client_auth(app_id, token_settings || { access_token: '' })
      end
    end

  end
end
