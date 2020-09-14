source 'https://rubygems.org'

# The core framework
# https://github.com/rails/rails
gem 'rails', '6.0.3.3'

# The backing band
gem 'rack', '~> 2.2.3'
gem 'rack-cors', '~> 1.1.1'
gem 'rake', '~> 13.0.1'

# DB adapters
gem 'activerecord-jdbc-adapter', '~> 60.2'
gem 'activerecord-jdbcpostgresql-adapter', '~> 60.2'
gem 'activerecord-jdbcsqlite3-adapter', '~> 60.2', group: [:test]
# Oracle adapter requires ojdb7.jar; exclude from test environments.
gem 'activerecord-oracle_enhanced-adapter', '~> 6.0.4', group: [:development, :production]

gem 'responders', '~> 3.0.1'

# http://flori.github.com/json/
gem 'json', '~> 2.3.1-java'

# CAS Strategy for OmniAuth. ETS maintains its own fork with SAML Ticket Validator capability,
# provided by Steven Hansen.
gem 'omniauth-cas', '~> 1.1.0', git: 'https://github.com/ets-berkeley-edu/omniauth-cas.git'

# LDAP
gem 'net-ldap', '~> 0.16.3'

# secure_headers provides x-frame, csp and other http headers
gem 'secure_headers', '~> 6.3.1'

gem 'faraday', '~> 0.9.0'
gem 'faraday_middleware', '~> 0.9.1'
gem 'httparty', '~> 0.18.1'

gem 'google-api-client', '0.32.1'
gem 'google_drive', '~> 3.0.5'
# OAuth2 for Google
gem 'signet', '~> 0.10.0'

# LTI support
gem 'ims-lti', git: 'https://github.com/instructure/ims-lti.git', branch: '1.2.x'

# for memcached connection
gem 'dalli', '~> 2.7.2'

# We fork Log4r, which is no longer actively maintained at the source.
gem 'log4r', '~> 1.1', git: 'https://github.com/ets-berkeley-edu/log4r'

# for easier non-DB-backed models
gem 'active_attr', '~> 0.15.0'

gem 'jruby-openssl', '0.10.4'

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

# 5.0.2 seems to be as high as we can presently go on JRuby.
# https://github.com/net-ssh/net-ssh/issues/655
gem 'net-ssh', '5.0.2'

gem 'net-telnet', '~> 0.2.0'

gem 'icalendar', '~> 2.2.2'

gem 'rubyzip', '~> 1.3.0'

# Data Loch integration
gem 'aws-sdk-s3', '~> 1.8.2'

group :development, :production do
  gem 'rvm-capistrano', '~> 1.5.6'
  gem 'capistrano', '~> 2.15.9'
end

group :development, :test do
  # Currently needed by RubyMine.
  gem 'test-unit'

  gem 'rspec-core', '~> 3.9.2'
  gem 'rspec-rails', '~> 4.0.1'
  gem 'rspec-mocks', '~> 3.9.1'
  gem 'rspec-support', '~> 3.9.3'
  gem 'rspec-its', '~> 1.3.0'
  gem 'rspec-collection_matchers', '~> 1.2.0'
  gem 'minitest-reporters', '~> 1.0.8'

  # We need to specify the latest webdriver here, to support the latest firefox
  gem 'selenium-webdriver', '~> 3.142.7'

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
end

group :test do
  gem 'page-object', '~> 2.2.6'
end

group :production do
  # For clustering on Tomcat.
  gem 'jruby-activemq', '~> 5.13.0', git: 'https://github.com/ets-berkeley-edu/jruby-activemq.git'
end

group :shell_debug do
  gem 'ruby-debug', '>= 0.10.5.rc9'
end
