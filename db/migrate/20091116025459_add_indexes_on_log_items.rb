class AddIndexesOnLogItems < ActiveRecord::Migration
  def self.up
    add_index :log_items, :reviewed_on
    add_index :log_items, :flagged_on
    add_index :log_items, :loggable_type
    add_index :log_items, :loggable_id
    add_index :log_items, :person_id
    add_index :log_items, :group_id
    add_index :log_items, :created_at
  end

  def self.down
    remove_index :log_items, :reviewed_on
    remove_index :log_items, :flagged_on
    remove_index :log_items, :loggable_type
    remove_index :log_items, :loggable_id
    remove_index :log_items, :person_id
    remove_index :log_items, :group_id
    remove_index :log_items, :created_at
  end
end
