class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index "families", ["last_name", "name"], :name => "index_family_names"
  end

  def self.down
    remove_index "families", :name => "index_family_names"
  end
end
