class AddApprovedToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :approved, :boolean, :default => false
    Group.update_all "approved = 1"
  end

  def self.down
    remove_column :groups, :approved
  end
end
