class AddNameToLogItems < ActiveRecord::Migration
  def self.up
    add_column :log_items, :name, :string, :limit => 255
  end

  def self.down
    remove_column :log_items, :name
  end
end
