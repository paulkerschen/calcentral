source 'https://rubygems.org'

# The core framework
# https://github.com/rails/rails
gem 'rails', '5.0.7.2'

gem 'actionpack-action_caching', '~>1.2.1'
gem 'actionpack-page_caching', '~>1.1.1'
gem 'actionpack-xml_parser', '~>1.0.1'
gem 'activerecord-session_store', '~>1.1.0'
gem 'rails-observers', '~>0.1.2'
gem 'responders', '~> 2.0'

gem 'rake', '~> 12.3.3'

gem 'rack', '~> 2.2.3'

gem 'activerecord-jdbc-adapter', '~> 50.7'

# Postgresql adapter
gem 'activerecord-jdbcpostgresql-adapter', '~> 50.7'

# A JSON implementation as a Ruby extension in C
# http://flori.github.com/json/
gem 'json', '~> 1.8.0'

# CAS Strategy for OmniAuth. ETS maintains its own fork with SAML Ticket Validator capability,
# provided by Steven Hansen.
gem 'omniauth-cas', '~> 1.1.0', git: 'https://github.com/ets-berkeley-edu/omniauth-cas.git'

# LDAP
gem 'net-ldap', '~> 0.16.0'

# secure_headers provides x-frame, csp and other http headers
gem 'secure_headers', '~> 5.0.5'

gem 'faraday', '~> 0.9.0'
gem 'faraday_middleware', '~> 0.9.1'
gem 'httparty', '~> 0.13.3'

# OAuth2 support
gem 'signet', '~> 0.10.0'
gem 'google-api-client', '0.32.1'
gem 'google_drive', '~> 3.0.5'

# LTI support
gem 'ims-lti', :git => 'https://github.com/instructure/ims-lti.git'

# for memcached connection
gem 'dalli', '~> 2.7.2'

# smarter logging
gem 'log4r', '~> 1.1'

# for easier non-DB-backed models
gem 'active_attr', '~> 0.15.0'

# for production deployment
gem 'jruby-activemq', '~> 5.13.0', git: 'https://github.com/ets-berkeley-edu/jruby-activemq.git'

# To support SSL TLSv1.2.
# jruby-openssl versions 0.9.8 through 0.9.16 trigger runaway memory consumption in CalCentral.
# Track progress at https://github.com/jruby/jruby-openssl/issues/86 and SISRP-18781.
gem 'jruby-openssl', '0.9.19'

# for parsing formatted html
gem 'nokogiri', '~> 1.10.8', platforms: :jruby

# for parsing paged feeds
gem 'link_header', '~> 0.0.7'

# Background jobs
gem 'concurrent-ruby', '~> 1.0'

# for building a WAR to deploy on Tomcat
gem 'warbler', '~> 2.0.5'
gem 'jruby-jars', '9.2.0.0'

# for trying, and trying again, and then giving up.
gem 'retriable', '~> 2.0'

# authorization abstraction layer
gem 'pundit', '~> 0.3.0'

gem 'net-ssh', '~>2.9.2' # v3 requires Ruby 2.0
gem 'net-telnet', '~> 0.2.0'

gem 'icalendar', '~> 2.2.2'

gem 'rubyzip', '~> 1.3.0'

# Data Loch integration
gem 'aws-sdk-s3', '~> 1.8.2'

# Closure Compiler Gem for JS compression
# https://github.com/documentcloud/closure-compiler
gem 'closure-compiler', '~> 1.1.11'

# Oracle adapter
# Purposely excluding this for test environments since folks have to install ojdbc6
group :development, :production do
  gem 'activerecord-oracle_enhanced-adapter', '~> 1.7.11'
  gem 'rvm-capistrano', '~> 1.3.1'
  gem 'capistrano', '~> 2.15.4'
end

group :development, :test do
  # Currently needed by RubyMine.
  gem 'test-unit'

  gem 'rspec-core', '~> 3.9.2'
  gem 'rspec-rails', '~> 4.0.1'
  gem 'rspec-mocks', '~> 3.9.1'
  gem 'rspec-support', '~> 3.9.3'
  gem 'rspec-its', '~> 1.1.0'
  gem 'rspec-collection_matchers', '~> 1.2.0'
  gem 'minitest-reporters', '~> 1.0.8'

  # We need to specify the latest webdriver here, to support the latest firefox
  gem 'selenium-webdriver', '~> 3.142.7'

  # Code coverage for Ruby 1.9 with a powerful configuration library and automatic merging of coverage across test suites
  # https://rubygems.org/gems/simplecov
  gem 'simplecov', '~> 0.14.0', require: false
  gem 'simplecov-html', '~> 0.10.0', require: false

  # Capybara is an integration testing tool for rack based web applications.
  # It simulates how a user would interact with a website
  # https://rubygems.org/gems/capybara
  gem 'capybara', '~> 2.7.1'

  # Headless is a Ruby interface for Xvfb. It allows you to create a headless display straight
  # from Ruby code, hiding some low-level action.
  gem 'headless', '~> 1.0.2'

  # Webmock is not thread-safe and should never be enabled in production-like environments.
  gem 'webmock', '~> 1.20.4'
end

group :development do
  # A better development webserver than WEBrick, especially on JRuby
  gem 'puma', '~> 3.12.6'

  # Automatically reloads your browser when 'view' files are modified.
  # https://github.com/guard/guard-livereload
  gem 'guard-livereload', '~> 2.4.0', require: false

  # To support debug in Torquebox.
  gem 'ruby-debug-ide', '~> 0.6.0'
end

group :test do
  gem 'activerecord-jdbcsqlite3-adapter', '~> 50.7'
  gem 'page-object', '~> 2.2.6'

  # RSpec results that Hudson + Bamboo + xml happy CI servers can read. See https://rubygems.org/gems/rspec_junit_formatter
  # TODO: Use gem 'rspec_junit_formatter', '~> 0.2.x' when deprecated concern of CLC-3565 is resolved.
  gem 'rspec_junit_formatter', :git => 'https://github.com/sj26/rspec_junit_formatter.git'
end

group :shell_debug do
  gem 'ruby-debug', '>= 0.10.5.rc9'
end
