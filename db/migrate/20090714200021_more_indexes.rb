class MoreIndexes < ActiveRecord::Migration
  def self.up
    add_index "pictures", ["album_id"], :name => "index_pictures_on_album_id"
  end

  def self.down
    remove_index "pictures", :name => "index_pictures_on_album_id"
  end
end
