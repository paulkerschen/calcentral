Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  config.dependency_loading = true if $rails_rake_task

  # Code is not reloaded between requests
  config.cache_classes = true

  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = Settings.application.serve_static_assets

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  Cache::Config.setup_cache_store config

end
