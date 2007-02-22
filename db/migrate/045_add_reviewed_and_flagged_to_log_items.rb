class AddReviewedAndFlaggedToLogItems < ActiveRecord::Migration
  def self.up
    add_column :log_items, :reviewed_on, :datetime
    add_column :log_items, :reviewed_by, :integer
    add_column :log_items, :flagged_on, :datetime
    add_column :log_items, :flagged_by, :integer
  end

  def self.down
    remove_column :log_items, :reviewed_on
    remove_column :log_items, :reviewed_by
    remove_column :log_items, :flagged_on
    remove_column :log_items, :flagged_by
  end
end
