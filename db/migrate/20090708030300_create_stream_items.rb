class CreateStreamItems < ActiveRecord::Migration
  def self.up
    create_table :stream_items do |t|
      t.integer :site_id
      t.string :description, :limit => 500
      t.string :title, :limit => 255
      t.text :body
      t.integer :album_id
      t.integer :person_id
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
  end

  def self.down
    drop_table :stream_items
  end
end
