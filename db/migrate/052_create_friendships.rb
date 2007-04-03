class CreateFriends < ActiveRecord::Migration
  def self.up
    create_table :friendships do |t|
      t.column :person_id, :integer
      t.column :friend_id, :integer
      t.column :confirmed, :boolean, :default => false
    end
  end

  def self.down
    drop_table :friendships
  end
end
