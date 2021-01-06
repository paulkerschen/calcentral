class AddTimestampsToCanvasSiteMailingListMembers < ActiveRecord::Migration[6.0]
  def change
    add_column :canvas_site_mailing_list_members, :deleted_at, :datetime
    add_index :canvas_site_mailing_list_members, :deleted_at
    add_column :canvas_site_mailing_list_members, :welcomed_at, :datetime
    add_index :canvas_site_mailing_list_members, :welcomed_at
  end
end
