source 'https://rubygems.org'

# The core framework
# https://github.com/rails/rails
gem 'rails', '4.2.11.1'

gem 'actionpack-action_caching', '~>1.1.1'
gem 'actionpack-page_caching', '~>1.0.2'
gem 'actionpack-xml_parser', '~>1.0.1'
gem 'actionview-encoded_mail_to', '~>1.0.5'
gem 'activerecord-session_store', '~>1.1.0'
gem 'activeresource', '~>4.0.0'
gem 'protected_attributes', '~> 1.0.8'
gem 'rails-observers', '~>0.1.2'
gem 'rails-perftest', '~>0.0.5'
gem 'responders', '~> 2.0'

gem 'rake', '~> 12.3.3'

# ETS is temporarily maintaining its own fork of Rack to support the SameSite=None cookie property.
gem 'rack', '~> 1.6.13', git: 'https://github.com/ets-berkeley-edu/rack.git', branch: 'ets-1-6-samesite'

gem 'activerecord-jdbc-adapter', '~> 1.3.16'

# Postgresql adapter
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.16'

# H2 adapter
gem 'activerecord-jdbch2-adapter', '~> 1.3.16'

# A JSON implementation as a Ruby extension in C
# http://flori.github.com/json/
gem 'json', '~> 1.8.0'

# CAS Strategy for OmniAuth. ETS maintains its own fork with SAML Ticket Validator capability,
# provided by Steven Hansen.
gem 'omniauth-cas', '~> 1.1.0', git: 'https://github.com/ets-berkeley-edu/omniauth-cas.git'

# LDAP
gem 'net-ldap', '~> 0.16.0'

# secure_headers provides x-frame, csp and other http headers
gem 'secure_headers', '~> 3.9.0'

gem 'faraday', '~> 0.9.0'
gem 'faraday_middleware', '~> 0.9.1'
gem 'httparty', '~> 0.13.3'

# OAuth2 support
gem 'signet', '~> 0.7.2'
gem 'google-api-client', '~> 0.8.6'
gem 'google_drive', '~> 1.0.6'

# LTI support
gem 'ims-lti', '~> 1.1.8', :git => 'https://github.com/instructure/ims-lti.git'

# for memcached connection
gem 'dalli', '~> 2.7.2'

# smarter logging
gem 'log4r', '~> 1.1'

# for easier non-DB-backed models
gem 'active_attr', '~> 0.8.5'

# for production deployment
gem 'jruby-activemq', '~> 5.13.0', git: 'https://github.com/ets-berkeley-edu/jruby-activemq.git'

# To support SSL TLSv1.2.
# jruby-openssl versions 0.9.8 through 0.9.16 trigger runaway memory consumption in CalCentral.
# Track progress at https://github.com/jruby/jruby-openssl/issues/86 and SISRP-18781.
gem 'jruby-openssl', '0.9.19'

# for parsing formatted html
gem 'nokogiri', '~> 1.10.8', :platforms => :jruby

# for parsing paged feeds
gem 'link_header', '~> 0.0.7'

# for simplified relational data management
gem 'rails_admin', '1.3.0'

gem 'bootstrap-sass', '~> 3.4.1'

# Background jobs without TorqueBox
gem 'concurrent-ruby', '~> 1.0.5'

# TorqueBox app server
gem 'torquebox', '~> 3.2.0'
gem 'torquebox-server', '~> 3.2.0'
gem 'torquebox-messaging', '~> 3.2.0'
gem 'jmx', '~> 1.0'

# for building a WAR to deploy on Tomcat
gem 'warbler', '~> 2.0.4'

# for trying, and trying again, and then giving up.
gem 'retriable', '~> 1.4'

# authorization abstraction layer
gem 'pundit', '~> 0.3.0'

gem 'cancan', '~> 1.6.10'
gem 'net-ssh', '~>2.9.2' # v3 requires Ruby 2.0

gem 'icalendar', '~> 2.2.2'

gem 'rubyzip', '~> 1.3.0'

# Data Loch integration
gem 'aws-sdk-s3', '~> 1.8.2'

##################################
# Front-end Gems for Rails Admin #
##################################


# Closure Compiler Gem for JS compression
# https://github.com/documentcloud/closure-compiler
gem 'closure-compiler', '~> 1.1.11'

# Oracle adapter
# Purposely excluding this for test environments since folks have to install ojdbc6
group :development, :production do
  gem 'activerecord-oracle_enhanced-adapter', '~> 1.6.0'
  gem 'rvm-capistrano', '~> 1.3.1'
  gem 'capistrano', '~> 2.15.4'
end

group :development, :test do
  # Currently needed by RubyMine.
  gem 'test-unit'

  gem 'rspec-core', '~> 3.4.0'
  gem 'rspec-rails', '~> 3.4.1'
  gem 'rspec-mocks', '~> 3.4.0'
  gem 'rspec-support', '~> 3.4.0'
  gem 'rspec-its', '~> 1.1.0'
  gem 'rspec-collection_matchers', '~> 1.1.2'
  gem 'minitest-reporters', '~> 1.0.8'

  # We need to specify the latest webdriver here, to support the latest firefox
  gem 'selenium-webdriver', '~> 2.53.4'

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

  # Spork can speed up multiple test runs.
  gem 'spork','1.0.0rc0'
  gem 'guard-spork'
  gem 'spork-rails'

  # Webmock is not thread-safe and should never be enabled in production-like environments.
  gem 'webmock', '~> 1.20.4'
end

group :development do
  # A better development webserver than WEBrick, especially on JRuby
  gem 'puma', '~> 3.12.2'

  # Automatically reloads your browser when 'view' files are modified.
  # https://github.com/guard/guard-livereload
  gem 'guard-livereload', '~> 2.4.0', require: false

  # To support debug in Torquebox.
  gem 'ruby-debug-ide', '~> 0.6.0'
end

group :test do
  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.16'
  gem 'page-object', '~> 1.2.0'

  # RSpec results that Hudson + Bamboo + xml happy CI servers can read. See https://rubygems.org/gems/rspec_junit_formatter
  # TODO: Use gem 'rspec_junit_formatter', '~> 0.2.x' when deprecated concern of CLC-3565 is resolved.
  gem 'rspec_junit_formatter', :git => 'https://github.com/sj26/rspec_junit_formatter.git'
end

group :shell_debug do
  gem 'ruby-debug', '>= 0.10.5.rc9'
end
