class ChangeGroupAttributes < ActiveRecord::Migration
  def self.up
    rename_column :groups, :archived, :hidden
    Group.find_all_by_subscription(true).each { |g| g.update_attribute :hidden, true }
    remove_column :groups, :subscription
  end

  def self.down
    rename_column :groups, :hidden, :archived
    add_column :groups, :subscription
  end
end
