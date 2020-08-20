module GoogleApps
  class CredentialStore
    include ClassLogger

    GOOGLE_APP_ID = 'Google'
    OEC_APP_ID = 'OEC'

    def initialize(app_id)
      @app_id = app_id
    end

    # Do not change the signature of this method because it is invoked by the Google Auth library
    # See https://github.com/googleapis/google-auth-library-ruby#storage
    def load(user_id)
      raise ArgumentError, 'User id cannot be blank' if user_id.blank?
      settings = CredentialStore.settings_of @app_id
      oauth2_data = User::Oauth2Data.get(user_id, @app_id)
      return nil if oauth2_data.empty?
      token_data = {
        client_id: settings[:client_id],
        scope: settings[:scope],
        access_token: oauth2_data[:access_token],
        refresh_token: oauth2_data[:refresh_token],
        expiration_time_millis: oauth2_data[:expiration_time].to_i * 1000,
      }
      token_data.to_json
    end

    # Do not change the signature of this method because it is invoked by the Google Auth library
    # See https://github.com/googleapis/google-auth-library-ruby#storage
    def store(user_id, token_data_string)
      raise ArgumentError, 'User id cannot be blank' if user_id.blank?
      Rails.logger.debug "Storing token data: user_id: #{user_id}"
      token_data = MultiJson.load token_data_string
      access_token = token_data['access_token']
      refresh_token = token_data['refresh_token']
      raise ArgumentError, 'Refresh token cannot be blank' if refresh_token.blank?
      expiration_time = token_data['expiration_time_millis'].to_i / 1000
      options = {
        app_data: {
          client_id: token_data['client_id'],
          scope: token_data['scope'],
        }
      }
      User::Oauth2Data.new_or_update(user_id, @app_id, access_token, refresh_token, expiration_time, options)
    end

    # Do not change the signature of this method because it is invoked by the Google Auth library
    # See https://github.com/googleapis/google-auth-library-ruby#storage
    def delete(user_id)
      User::Oauth2Data.remove(user_id, @app_id)
    end

    def self.config_of(app_id = nil)
      case app_id
        when GOOGLE_APP_ID then Settings.google_proxy
        when OEC_APP_ID then Settings.oec.google
        else nil
      end
    end

    def self.settings_of(app_id)
      return nil unless (settings = self.config_of app_id)
      {
        client_id: settings.client_id,
        client_secret: settings.client_secret,
        scope: settings.scope
      }
    end

    def self.access_granted?(user_id, app_id = APP_ID)
      self.config_of(app_id).fake || User::Oauth2Data.get(user_id, app_id)[:access_token].present?
    end

  end
end
