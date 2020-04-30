require "rvm/capistrano"
require "bundler/capistrano"
require_relative "settings/server_config"

settings = ServerConfig.get_settings(Dir.home + "/.calcentral_config/server_config.yml")

set :application, "Calcentral"

role(:junction_dev_host) { settings.dev.servers }
set :user, settings.common.user
set :branch, settings.common.branch
set :project_root, settings.common.root

# junction_dev is the IST configured server setup we have for junction-dev.berkeley.edu. It
# currently consists of 1 app server (which also runs memcached) and a shared postgres instance.

namespace :deploy_to_all_servers do
  desc "Invoked by S3-backed deploy script. Update and restart the targeted Junction tier."
  task :s3_artifact, :roles => :junction_dev_host do
    # Take everything offline first.
    servers = find_servers_for_task(current_task)

    transaction do
      servers.each_with_index do |server, index|
        # update source
        run "cd #{project_root}; ./script/deploy/_download-war-for-tomcat.sh", :hosts => server

        # Run db migrate on the first app server ONLY
        if index == 0
          logger.debug "---- Server: #{server.host} running migrate in transaction on offline app servers"
          run "cd #{project_root}; ./script/migrate.sh", :hosts => server
        end

        # start it up
        run "cd #{project_root}; ./script/deploy/_start-tomcat.sh", :hosts => server
      end
    end
  end
end
