class ChangeFlaggedByToStringOnLogItems < ActiveRecord::Migration
  def self.up
    remove_column :log_items, :flagged_by
    add_column :log_items, :flagged_by, :string, :limit => 255
  end

  def self.down
    remove_column :log_items, :flagged_by
    add_column :log_items, :flagged_by, :integer
  end
end
