Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  config.eager_load = true

  # Show full error reports and enable caching
  config.consider_all_requests_local       = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  # Set this to true if you want to compress the assets.
  config.assets.compress = false

  # Don't fallback to assets pipeline if a precompiled asset is missed
  # config.assets.compile = false

  # Expands the lines which load the assets
  config.assets.debug = false

  # Turn off all page, action, fragment caching
  config.action_controller.perform_caching = false

  Cache::Config.setup_cache_store config

end
