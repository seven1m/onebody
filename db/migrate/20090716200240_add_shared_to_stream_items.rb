class AddSharedToStreamItems < ActiveRecord::Migration
  def self.up
    change_table :stream_items do |t|
      t.boolean :shared
    end
  end

  def self.down
    change_table :stream_items do |t|
      t.remove :shared
    end
  end
end
