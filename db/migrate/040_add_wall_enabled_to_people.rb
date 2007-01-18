class AddWallEnabledToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :wall_enabled, :boolean
  end

  def self.down
    remove_column :people, :wall_enabled
  end
end
