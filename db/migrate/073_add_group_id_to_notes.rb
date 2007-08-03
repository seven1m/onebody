class AddGroupIdToNotes < ActiveRecord::Migration
  def self.up
    add_column :notes, :group_id, :integer
    rename_column :groups, :notes, :other_notes
  end

  def self.down
    remove_column :notes, :group_id
    rename_column :groups, :other_notes, :notes
  end
end
