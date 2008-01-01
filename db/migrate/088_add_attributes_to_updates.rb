class AddAttributesToUpdates < ActiveRecord::Migration
  def self.up
    add_column :updates, :suffix, :string, :limit => 25
    add_column :updates, :gender, :string, :limit => 6
    add_column :updates, :family_name, :string, :limit => 255
    add_column :updates, :family_last_name, :string, :limit => 255
  end

  def self.down
    remove_column :updates, :suffix
    remove_column :updates, :gender
    remove_column :updates, :family_name
    remove_column :updates, :family_last_name
  end
end
