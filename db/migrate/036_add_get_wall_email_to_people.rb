class AddGetWallEmailToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :get_wall_email, :boolean, :default => true
  end

  def self.down
    remove_column :people, :get_wall_email
  end
end
