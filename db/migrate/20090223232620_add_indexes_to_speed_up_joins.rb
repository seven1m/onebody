class AddIndexesToSpeedUpJoins < ActiveRecord::Migration
  def self.up
    add_index :memberships, :person_id
    add_index :memberships, :group_id
    add_index :groups, :category
    add_index :friendships, :person_id
    add_index :friendships, :friend_id
    add_index :friendship_requests, :person_id
    add_index :updates, :person_id
    add_index :blog_items, :person_id
    add_index :sites, :host
    add_index :messages, :wall_id
    add_index :messages, :created_at
    add_index :people, :family_id
  end

  def self.down
    remove_index :people, :family_id
    remove_index :messages, :created_at
    remove_index :messages, :wall_id
    remove_index :sites, :host
    remove_index :blog_items, :person_id
    remove_index :updates, :person_id
    remove_index :friendship_requests, :person_id
    remove_index :friendships, :friend_id
    remove_index :friendships, :person_id
    remove_index :groups, :category
    remove_index :memberships, :group_id
    remove_index :memberships, :person_id
  end
end
