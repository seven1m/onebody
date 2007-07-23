class MoreAdminPrivileges < ActiveRecord::Migration
  def self.up
    add_column :admins, :manage_notes, :boolean, :default => false
    add_column :admins, :manage_messages, :boolean, :default => false
    add_column :admins, :view_hidden_profiles, :boolean, :default => false
    add_column :admins, :manage_prayer_signups, :boolean, :default => false
    add_column :admins, :manage_comments, :boolean, :default => false
    add_column :admins, :manage_events, :boolean, :default => false
    add_column :admins, :manage_recipes, :boolean, :default => false
    add_column :admins, :manage_pictures, :boolean, :default => false
    add_column :admins, :manage_access, :boolean, :default => false
    add_column :admins, :view_log, :boolean, :default => false
    remove_column :admins, :view_music
  end

  def self.down
    remove_column :admins, :manage_notes
    remove_column :admins, :manage_messages
    remove_column :admins, :view_hidden_profiles
    remove_column :admins, :manage_prayer_signups
    remove_column :admins, :manage_comments
    remove_column :admins, :manage_events
    remove_column :admins, :manage_recipes
    remove_column :admins, :manage_pictures
    remove_column :admins, :manage_access
    remove_column :admins, :view_log
    add_column :admins, :view_music, :boolean, :default => false
  end
end
