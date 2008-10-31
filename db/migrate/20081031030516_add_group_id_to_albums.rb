class AddGroupIdToAlbums < ActiveRecord::Migration
  def self.up
    add_column :albums, :group_id, :integer
    add_column :groups, :pictures, :boolean, :default => true
  end

  def self.down
    remove_column :albums, :group_id
    remove_column :groups, :pictures
  end
end
