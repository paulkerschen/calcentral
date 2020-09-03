same_site = if Rails.env.development? then :lax else :none end

Rails.application.config.session_store :cookie_store,
  :key => '_calcentral_session',
  :expire_after => Settings.application.session_expiration,
  :same_site => same_site
