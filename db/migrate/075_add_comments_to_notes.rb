class AddCommentsToNotes < ActiveRecord::Migration
  def self.up
    add_column :comments, :note_id, :integer
  end

  def self.down
    remove_column :comments, :note_id
  end
end
