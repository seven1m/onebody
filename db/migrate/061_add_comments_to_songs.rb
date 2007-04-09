class AddCommentsToSongs < ActiveRecord::Migration
  def self.up
    add_column :comments, :song_id, :integer
  end

  def self.down
    remove_column :comments, :song_id
  end
end
