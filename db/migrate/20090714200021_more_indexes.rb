class MoreIndexes < ActiveRecord::Migration
  def self.up
    #add_index "people_verses", ["person_id"], :name => "index_people_verses_on_person_id"
    #add_index "albums", ["created_at"], :name => "index_albums_on_created_at"
    add_index "pictures", ["album_id"], :name => "index_pictures_on_album_id"
  end

  def self.down
    #remove_index :name => "index_people_verses_on_person_id"
    #remove_index :name => "index_albums_on_created_at"
    #remove_index :name => "index_pictures_on_album_id"
  end
end
