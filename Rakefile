#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

# Rails.logger might not be initialized for certain rake tasks, see calcentral_config.rb
Rails.logger ||= Logger.new(STDOUT)
