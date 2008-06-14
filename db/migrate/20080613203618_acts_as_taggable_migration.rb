class ActsAsTaggableMigration < ActiveRecord::Migration
  def self.up
    create_table :taggings do |t|
      t.column :tag_id, :integer
      t.column :taggable_id, :integer
      t.column :taggable_type, :string
      t.column :created_at, :datetime
    end
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type]
    conn = ActiveRecord::Base.connection
    conn.select_all('select * from tags_verses').each do |tagging|
      conn.execute("insert into taggings (tag_id, taggable_id, taggable_type) values (#{tagging['tag_id']}, #{tagging['verse_id']}, 'Verse')")
    end
    drop_table :tags_verses
  end
  
  def self.down
    create_table :tags_verses, :id => false do |t|
      t.integer :tag_id
      t.integer :verse_id
    end
    conn = ActiveRecord::Base.connection
    conn.select_all("select * from taggings where taggable_type = 'Verse'").each do |tagging|
      conn.execute("insert into tags_verses (tag_id, verse_id) values (#{tagging['tag_id']}, #{tagging['taggable_id']})")
    end
    drop_table :taggings
  end
end
