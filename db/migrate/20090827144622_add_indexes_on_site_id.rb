class AddIndexesOnSiteId < ActiveRecord::Migration
  def self.up
    add_index "people", ["site_id"], :name => "index_site_id_on_people"
    add_index "groups", ["site_id"], :name => "index_site_id_on_groups"
    add_index "admins", ["site_id"], :name => "index_site_id_on_admins"
  end

  def self.down
    remove_index "people", :name => "index_site_id_on_people"
    remove_index "groups", :name => "index_site_id_on_groups"
    remove_index "admins", :name => "index_site_id_on_admins"
  end
end
