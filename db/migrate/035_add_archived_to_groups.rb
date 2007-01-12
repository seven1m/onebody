class AddArchivedToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :archived, :boolean, :default => false
  end

  def self.down
    remove_column :groups, :archived
  end
end
