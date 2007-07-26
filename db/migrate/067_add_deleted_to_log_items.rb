class AddDeletedToLogItems < ActiveRecord::Migration
  def self.up
    add_column :log_items, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :log_items, :deleted
  end
end
