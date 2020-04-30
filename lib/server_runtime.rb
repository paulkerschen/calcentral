class ServerRuntime
  def self.get_settings
    @server_settings ||= init_settings
    @server_settings
  end

  # Only needs to happen once, since the settings shouldn't change after the server starts
  def self.init_settings
    Rails.logger.info "#{self.name} Initializing settings"

    settings = {}
    settings['firstVisited'] = `date`.strip
    settings['hostname'] = `hostname`.strip

    begin
      git_file = File.open Rails.root.join('versions', 'git.txt')
      if git_file
        rev = git_file.read.strip
        Rails.logger.info "#{self.name} Using git version #{rev} from /versions/git.txt"
        settings['gitCommit'] = rev
      end
    rescue
      Rails.logger.info "#{self.name} Looking up git version from git command"
      settings['gitCommit'] = `git log --pretty=format:'%H' -n 1`.strip
    end

    migrations = Dir.glob "#{Rails.root}/db/migrate/*.rb"
    current_schema = File.basename(migrations.sort.last).split('_')[0]
    settings['versions'] = {
        'api' => File.open(Rails.root.join('versions', 'api.txt')).read.strip,
        'application' => File.open(Rails.root.join('versions', 'application.txt')).read.strip,
        'currentDbSchema' => current_schema,
        'previousReleaseDbSchema' => File.open(Rails.root.join('versions', 'previous_release_db_schema.txt')).read.strip
    }
    settings
  end
end
