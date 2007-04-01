class AddMusicAccessToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :music_access, :boolean, :default => false
  end

  def self.down
    remove_column :people, :music_access
  end
end
