namespace :canvas do

  def test_servers
    if (dev_test_canvases_string = ENV["DEV_TEST_CANVASES"])
      dev_test_canvases_string.split(',')
    else
      Settings.canvas_proxy.test_servers
    end
  end

  desc 'Add new guest user accounts, and update existing ones, within Canvas'
  task :guest_user_sync => :environment do
    canvas_worker = CanvasCsv::UpdateGuests.new
    canvas_worker.run
  end

  desc 'Performs incremental sync of new active CalNet users in Canvas'
  task :new_user_sync => :environment do |t, args|
    canvas_worker = CanvasCsv::AddNewUsers.new
    canvas_worker.sync_new_active_users
  end

  desc 'Exports Canvas enrollments to CSV files for each term'
  task :export_enrollments_to_csv_set => :environment  do
    canvas_worker = CanvasCsv::TermEnrollments.new
    canvas_worker.export_enrollments_to_csv_set
  end

  desc 'Get all Canvas users and sections for current terms, refresh user accounts, and add new section memberships'
  task :full_refresh => :environment do
    canvas_worker = CanvasCsv::RefreshCampusDataAll.new
    canvas_worker.run
  end

  desc 'Get recent enrollment updates to Canvas-linked sections for current terms, refresh user accounts, and add new section memberships'
  task :recent_refresh => :environment do
    canvas_worker = CanvasCsv::RefreshCampusDataRecent.new
    canvas_worker.run
  end

  desc 'Get all Canvas users and refresh user accounts'
  task :user_accounts_refresh => :environment do
    canvas_worker = CanvasCsv::RefreshCampusDataAccounts.new
    canvas_worker.run
  end

  desc "Delete email addresses from inactivated bCourses accounts"
  task :delete_inactive_emails => :environment do
    users_csv_file = ENV['USERS_CSV']
    unless users_csv_file
      # Ensure that the download directory exists in the file system.
      CanvasCsv::Base.new()
      users_csv_file = "#{Settings.canvas_proxy.export_directory}/provisioned-users-#{DateTime.now.strftime('%F-%H-%M')}.csv"
      users_csv_file = Canvas::Report::Users.new(download_to_file: users_csv_file).get_csv
    end
    inactivated = []
    CSV.foreach(users_csv_file, headers: true) {|row| inactivated << row['canvas_user_id'] if row['login_id'].start_with? 'inactive-'}
    Rails.logger.warn "Found #{inactivated.length} inactivated users"
    if inactivated.present?
      CanvasCsv::MaintainUsers.new([], []).handle_email_deletions inactivated
    end
  end

  desc 'Add QA/Dev admin (TEST_ADMIN_ID="some_test_admin" DEV_TEST_CANVASES="https://ucb.beta.example.com,https://ucb.test.example.com")'
  task :add_test_admin => :environment do
    test_admin_id = ENV["TEST_ADMIN_ID"] || Settings.canvas_proxy.test_admin_id
    non_production_canvases = test_servers
    if test_admin_id.blank?
      Rails.logger.error 'Must specify TEST_ADMIN_ID="some_test_admin"'
    elsif non_production_canvases.blank?
      Rails.logger.error 'Must specify DEV_TEST_CANVASES="https://ucb.beta.example.com,https://ucb.test.example.com"'
    else
      Canvas::Admins.add_admin_to_servers(test_admin_id, non_production_canvases)
      Rails.logger.info "Admins update complete for #{non_production_canvases}"
    end
  end

  desc 'Reconfigure CAS URL (TEST_CAS_URL="https://auth-test.example.com/cas" DEV_TEST_CANVASES="https://ucb.beta.example.com,https://ucb.test.example.com")'
  task :reconfigure_auth_url => :environment do
    test_cas_url = ENV["TEST_CAS_URL"] || Settings.canvas_proxy.test_cas_url
    non_production_canvases = test_servers
    if test_cas_url.blank?
      Rails.logger.error 'Must specify TEST_CAS_URL="https://auth-test.example.com/cas"'
    elsif non_production_canvases.blank?
      Rails.logger.error 'Must specify DEV_TEST_CANVASES="https://ucb.beta.example.com,https://ucb.test.example.com"'
    else
      CanvasLti::ReconfigureAuthorizationConfigs.reconfigure(test_cas_url, non_production_canvases)
      Rails.logger.info "Reconfiguration complete for #{non_production_canvases}"
    end
  end

  desc 'Configure all default Canvas external apps provided by the current server'
  task :configure_all_apps_from_current_host => :environment do
    results = CanvasLti::ReconfigureExternalApps.new.configure_all_apps_from_current_host
    Rails.logger.info "Configured external apps: #{results}"
  end

  desc 'Repair Canvas Course SIS IDs (TERM_ID=x)'
  task :repair_course_sis_ids => :environment do
    term_id = ENV["TERM_ID"]
    if (term_id.blank?)
      Rails.logger.error "Must specify TERM_ID=YourSisTermId"
    else
      canvas_worker = CanvasCsv::RepairSections.new
      canvas_worker.repair_sis_ids_for_term(term_id)
    end
  end

  desc 'Report TurnItIn usage for a term'
  task :report_turnitin => :environment do
    CanvasCsv::TurnitinReporter.new(ENV['TERM_ID']).run
  end

  desc 'Report LTI Apps enabled for a term'
  task :report_lti_usage => :environment do
    CanvasCsv::LtiUsageReporter.new(ENV["TERM_ID"]).run
  end

  desc 'Manage visibility of SIS-integrated LTI tools for a range of terms (TO_TERM="2016-C" FROM_TERM="2013-C" HIDE_THEM=true)'
  task :toggle_sis_lti_tools => :environment do
    to_term = ENV['TO_TERM']
    hide_them = ENV['HIDE_THEM']
    if to_term.blank? || hide_them.blank?
      Rails.logger.error 'Must specify TO_TERM="yyyy-B" HIDE_THEM=true_or_false'
    else
      hide_them = ('true'.casecmp(hide_them.to_s) == 0)
      options = {to_term: to_term, hide_them: hide_them}
      if ENV['FROM_TERM']
        options[:from_term] = ENV['FROM_TERM']
      end
      CanvasLti::ToggleSisLtiTools.new(options).run
    end
  end

end
