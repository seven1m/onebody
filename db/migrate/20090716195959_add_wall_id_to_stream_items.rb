class AddWallIdToStreamItems < ActiveRecord::Migration
  def self.up
    change_table :stream_items do |t|
      t.integer :wall_id
    end
  end

  def self.down
    change_table :stream_items do |t|
      t.remove :wall_id
    end
  end
end
