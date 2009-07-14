class CreateStreamItems < ActiveRecord::Migration
  def self.up
    create_table :stream_items do |t|
      t.integer :site_id
      t.string :title, :limit => 500
      t.text :body
      t.text :context
      t.integer :person_id
      t.integer :group_id
      t.references :streamable, :polymorphic => true
      t.timestamps
    end
    Site.each do
      LogItem.all(
        :conditions => [
          "deleted = ? and group_id is null and loggable_type in (?)",
          false,
          %w(Verse Recipe Note Picture)
        ]
      ).each do |log_item|
        log_item.create_as_stream_item
      end
    end
    
    add_index "stream_items", ["created_at"], :name => "index_stream_items_on_created_at"
    add_index "stream_items", ["person_id"], :name => "index_stream_items_on_person_id"
    add_index "stream_items", ["group_id"], :name => "index_stream_items_on_group_id"
    add_index "stream_items", ["streamable_type", "streamable_id"], :name => "index_stream_items_on_streamable_type_and_streamable_id"
  end

  def self.down
    drop_table :stream_items
    remove_index :name => "index_stream_items_on_created_at"
    remove_index :name => "index_stream_items_on_person_id"
    remove_index :name => "index_stream_items_on_group_id"
    remove_index :name => "index_stream_items_on_streamable_type_and_streamable_id"
  end
end
