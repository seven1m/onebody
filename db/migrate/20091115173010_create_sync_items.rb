class CreateSyncItems < ActiveRecord::Migration
  def self.up
    create_table :sync_items do |t|
      t.integer :site_id
      t.integer :sync_id
      t.references :syncable, :polymorphic => true
      t.integer :legacy_id
      t.string :name, :limit => 255
      t.string :operation, :limit => 50
      t.string :status, :limit => 50
      t.text :error_messages
    end
    add_index "sync_items", ["sync_id"],                      :name => "index_sync_id_on_sync_items"
    add_index "sync_items", ["syncable_type", "syncable_id"], :name => "index_syncable_on_sync_items"
  end

  def self.down
    remove_index "sync_items", :name => "index_sync_id_on_sync_items"
    remove_index "sync_items", :name => "index_syncable_on_sync_items"
    drop_table :sync_items
  end
end
