class AddHomeGroupToMemberships < ActiveRecord::Migration
  def self.up
    add_column :memberships, :home_group, :boolean, :default => false
  end

  def self.down
    remove_column :memberships, :home_group
  end
end
