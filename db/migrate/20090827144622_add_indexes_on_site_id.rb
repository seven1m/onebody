class AddIndexesOnSiteId < ActiveRecord::Migration
  def self.up
    add_index "people", ["site_id"], :name => "index_site_id_on_people"
    add_index "groups", ["site_id"], :name => "index_site_id_on_groups"
  end

  def self.down
    remove_index :name => "index_site_id_on_people"
    remove_index :name => "index_site_id_on_groups"
  end
end
