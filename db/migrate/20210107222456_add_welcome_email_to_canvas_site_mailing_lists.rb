class AddWelcomeEmailToCanvasSiteMailingLists < ActiveRecord::Migration[6.0]
  def change
    add_column :canvas_site_mailing_lists, :welcome_email_active, :boolean, null: false, default: false
    add_column :canvas_site_mailing_lists, :welcome_email_subject, :text
    add_column :canvas_site_mailing_lists, :welcome_email_body, :text
  end
end
