module CanvasCsv

  # Generates and imports SIS User and Enrollment CSV dumps into Canvas based on campus SIS information.
  class RefreshCampusDataAccounts < RefreshCampusDataBase

    def initialize
      super
      initialize_user_csvs
    end

    def import_type
      'accounts'
    end

    def generate_csv_files
      generate_users_csv
    end

  end
end
