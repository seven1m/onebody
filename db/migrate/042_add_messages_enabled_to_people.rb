class AddMessagesEnabledToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :messages_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :people, :messages_enabled
  end
end
