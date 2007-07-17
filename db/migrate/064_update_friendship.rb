class UpdateFriendship < ActiveRecord::Migration
  def self.up
    remove_column :friendships, :confirmed
    add_column :friendships, :pending, :boolean, :default => true
    add_column :friendships, :rejected, :boolean, :default => false
    add_column :friendships, :initiated_by_id, :integer
    add_column :friendships, :rejected_by_id, :integer
    add_column :friendships, :created_at, :datetime
    add_column :friendships, :updated_at, :datetime
    add_column :friendships, :ordering, :integer, :default => 10000
  end

  def self.down
    add_column :friendships, :confirmed, :boolean, :default => false
    remove_column :friendships, :pending
    remove_column :friendships, :rejected
    remove_column :friendships, :initiated_by_id
    remove_column :friendships, :rejected_by_id
    remove_column :friendships, :created_at
    remove_column :friendships, :updated_at
    remove_column :friendships, :ordering
  end
end
