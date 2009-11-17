class IndexLogItemsOnSiteId < ActiveRecord::Migration
  def self.up
    add_index :log_items, :site_id
  end

  def self.down
    remove_index :log_items, :site_id
  end
end
