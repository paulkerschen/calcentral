class LinkToCampusSolutionsFromMyCampus < ActiveRecord::Migration
  def change
    Links::CampusLinkLoader.delete_links!
    Links::CampusLinkLoader.load_links! '/docs/json/campuslinks.json'
  end
end
