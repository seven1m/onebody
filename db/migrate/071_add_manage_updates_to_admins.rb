class AddManageUpdatesToAdmins < ActiveRecord::Migration
  def self.up
    add_column :admins, :manage_updates, :boolean, :default => false
  end

  def self.down
    remove_column :admins, :manage_updates
  end
end
