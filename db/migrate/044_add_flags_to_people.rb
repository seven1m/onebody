class AddFlagsToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :flags, :string, :limit => 255
  end

  def self.down
    remove_column :people, :flags
  end
end
