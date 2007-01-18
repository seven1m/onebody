class AddWallEnabledToFamilies < ActiveRecord::Migration
  def self.up
    add_column :families, :wall_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :families, :wall_enabled
  end
end
