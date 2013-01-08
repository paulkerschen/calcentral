source "https://rubygems.org"

# The core framework
# https://github.com/rails/rails
gem "rails", "3.2.10"

# Postgresql adapter
gem "activerecord-jdbcpostgresql-adapter", "~> 1.2.5"

# H2 adapter
gem "activerecord-jdbch2-adapter", "~> 1.2.5"

# A JSON implementation as a Ruby extension in C
# http://flori.github.com/json/
gem "json", "~> 1.7.5"

# CAS Strategy for OmniAuth
# https://rubygems.org/gems/omniauth-cas
gem "omniauth-cas", "~> 1.0.1"

gem "faraday", "~> 0.8.4"

# OAuth2 support
gem "signet", "~> 0.4.3"
gem "google-api-client", "~> 0.6.0"

# for VCR http recording tool
gem "vcr", "~> 2.4.0"
gem "jruby-openssl", "~> 0.8.2"

# for memcached connection
gem "dalli", "~> 2.6.0"

# smarter logging
gem "log4r", "~> 1.1.10"

# for easier non-DB-backed models
gem "active_attr", "~> 0.7.0"

# for production deployment
gem "trinidad", "~> 1.4.4"

# Addressable is a replacement for the URI implementation that is part of Ruby's standard library.
# https://github.com/sporkmonger/addressable
gem "addressable", "~> 2.3.2"

# for concurrency management
gem "celluloid", "~> 0.12.4"

# Gems used only for assets and not required
# in production environments by default.
group :assets do

  # This library adds angularjs support to Rails applications
  # https://github.com/ludicast/angular-rails
  gem "angular-rails", "~> 0.0.12"

  # CSS Framework - also includes Compass and SASS
  # https://github.com/zurb/foundation
  gem "sass-rails", "~> 3.2.3"
  gem "coffee-rails", "~> 3.2.1"
  gem "compass-rails", "~> 1.0.3"
  gem "zurb-foundation", "~> 3.2.0"

  # Ruby wrapper for UglifyJS JavaScript compressor
  # https://github.com/lautis/uglifier
  gem "uglifier", "~> 1.3.0"
end

# Oracle adapter
# Purposely excluding this for test environments since folks have to install ojdbc6
group :development, :testext, :production do
  gem "activerecord-oracle_enhanced-adapter", "~> 1.4.1"
  gem "rvm-capistrano", "~> 1.2.7"
  gem "capistrano", "~> 2.13.5"
end

group :development, :test , :testext do
  gem "rspec-rails", "~> 2.12.1"
  gem "minitest-reporters"

  # Test our JavaScript code.
  # https://github.com/pivotal/jasmine-gem
  gem "jasmine", "~> 1.3.1"
  gem "jquery-rails", "~> 2.1.4"
  gem "jasmine-jquery-rails", "~> 1.4.2"

  # We need to specify the latest webdriver here, to support the latest firefox
  gem "selenium-webdriver", "~> 2.27.2"

  gem "therubyrhino", "~> 2.0.1"

  # Code coverage for Ruby 1.9 with a powerful configuration library and automatic merging of coverage across test suites
  # https://rubygems.org/gems/simplecov
  gem "simplecov", "~> 0.7.1", :require => false

  # Capybara is an integration testing tool for rack based web applications.
  # It simulates how a user would interact with a website
  # https://rubygems.org/gems/capybara
  gem "capybara", "~> 2.0.2"
end

group :development do
  # Automatically reloads your browser when "view" files are modified.
  # https://github.com/guard/guard-livereload
  gem "guard-livereload", "~> 1.1.0"
  gem "rack-livereload", "~> 0.3.8"

  # Polling is evil:
  # https://github.com/guard/guard#readme
  gem "rb-inotify", "~> 0.8.8", :require => false
  gem "rb-fsevent", "~> 0.9.2", :require => false
  gem "rb-fchange", "~> 0.0.6", :require => false

  # Start/stop rails + guard all at once
  # http://stackoverflow.com/questions/8293747/need-a-less-repetitve-way-to-start-rails-on-mac-for-noob
  # https://github.com/ddollar/foreman
  gem "foreman", "~> 0.60.2"

  # C-Extension dependency of foreman
  # https://github.com/rtomayko/posix-spawn
  gem "posix-spawn", "~> 0.3.6"
end

group :test do
  gem "activerecord-jdbcsqlite3-adapter", "~> 1.2.5"
end

group :test, :testext do
  # RSpec results that Hudson + Bamboo + xml happy CI servers can read.
  # https://rubygems.org/gems/rspec_junit_formatter
  gem "rspec_junit_formatter", "~> 0.1.2"

  gem "webmock", "~> 1.9.0"
end
