class AddIndexAdminIdOnPeople < ActiveRecord::Migration
  def self.up
    add_index "people", ["admin_id"], :name => "index_admin_id_on_people"
  end

  def self.down
    remove_index "people", :name => "index_admin_id_on_people"
  end
end
