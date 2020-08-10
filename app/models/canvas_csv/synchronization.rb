module CanvasCsv
  # Provides object used to store synchronization states between campus systems and Canvas
  class Synchronization < ApplicationRecord
    include ActiveRecordHelper
    include ClassLogger

    self.table_name = 'canvas_synchronization'

    # Returns single record used to store synchronization timestamp(s)
    def self.get
      count = self.count
      if count == 0
        logger.warn 'Creating initial Canvas synchronization record'
        self.create(
          last_enrollment_sync: 1.days.ago.utc,
          last_guest_user_sync: 1.days.ago.utc,
          last_instructor_sync: 1.days.ago.utc,
        )
      elsif count > 1
        raise RuntimeError, 'Canvas synchronization data has more than one record!'
      end
      self.first
    end
  end
end
