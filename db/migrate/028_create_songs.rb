class CreateSongs < ActiveRecord::Migration
  def self.up
    create_table :songs do |t|
      t.column :title, :string, :limit => 255
      t.column :notes, :text
      t.column :artists, :string, :limit => 500
      t.column :album, :string, :limit => 255
      t.column :image_small_url, :string, :limit => 255
      t.column :image_medium_url, :string, :limit => 255
      t.column :image_large_url, :string, :limit => 255
      t.column :amazon_asin, :string, :limit => 50
      t.column :amazon_url, :string, :limit => 255
      t.column :created_at, :datetime
      t.column :person_id, :integer
    end
    create_table :songs_tags, :id => false do |t|
      t.column :song_id, :integer
      t.column :tag_id, :integer
    end
    add_column :attachments, :song_id, :integer
  end

  def self.down
    drop_table :songs
    drop_table :songs_tags
    remove_column :attachments, :song_id
  end
end
