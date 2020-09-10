Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = false

  config.eager_load = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Turn off all page, action, fragment caching
  config.action_controller.perform_caching = false

  Cache::Config.setup_cache_store config

end
