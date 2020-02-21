# Configuration for the secure_headers gem, which sets X-Frame and CSP headers.
# Docs at http://rubydoc.info/gems/secure_headers/0.5.0/frames
# Rails 4 will DENY X-Frame by default

module Calcentral
  class Application < Rails::Application
    config.before_initialize do
      SecureHeaders::Configuration.default do |config|
        # Disable most of the default headers provided by secure_headers gem, leaving x_frame and x_xss.
        config.x_frame_options = 'DENY'
        config.x_xss_protection = '1; mode=block'
        config.csp = SecureHeaders::OPT_OUT
        config.hsts = SecureHeaders::OPT_OUT
        config.x_content_type_options = SecureHeaders::OPT_OUT
        config.x_download_options = SecureHeaders::OPT_OUT
        config.x_permitted_cross_domain_policies = SecureHeaders::OPT_OUT
        config.referrer_policy = SecureHeaders::OPT_OUT
      end
    end
  end
end
