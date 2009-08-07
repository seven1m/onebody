class AddPublicToAlbums < ActiveRecord::Migration
  def self.up
    change_table :albums do |t|
      t.boolean :is_public, :default => true
    end
  end

  def self.down
    change_table :albums do |t|
      t.remove :is_public
    end
  end
end
