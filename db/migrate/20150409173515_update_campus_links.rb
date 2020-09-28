class UpdateCampusLinks < ActiveRecord::Migration
  def self.up
    Links::CampusLinkLoader.delete_links!
    Links::CampusLinkLoader.load_links! "/docs/json/campuslinks.json"
  end
end
