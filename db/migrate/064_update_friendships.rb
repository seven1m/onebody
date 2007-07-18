class UpdateFriendships < ActiveRecord::Migration
  def self.up
    remove_column :friendships, :confirmed
    add_column :friendships, :created_at, :datetime
    add_column :friendships, :ordering, :integer, :default => 1000
    add_column :people, :friends_enabled, :boolean, :default => true
    create_table :friendship_requests do |t|
      t.column :person_id, :integer
      t.column :from_id, :integer
      t.column :rejected, :boolean, :default => false
      t.column :created_at, :datetime
    end
  end

  def self.down
    add_column :friendships, :confirmed, :boolean, :default => false
    remove_column :friendships, :created_at
    remove_column :friendships, :ordering
    remove_column :people, :friends_enabled
    drop_table :friendship_requests
  end
end
