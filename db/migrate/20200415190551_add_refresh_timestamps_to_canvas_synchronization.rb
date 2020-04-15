class AddRefreshTimestampsToCanvasSynchronization < ActiveRecord::Migration
  def change
    add_column :canvas_synchronization, :last_enrollment_sync, :datetime
    add_column :canvas_synchronization, :last_instructor_sync, :datetime
  end
end
