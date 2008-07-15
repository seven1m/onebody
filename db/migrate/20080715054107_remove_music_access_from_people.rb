class RemoveMusicAccessFromPeople < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.remove :music_access
    end
  end

  def self.down
    change_table :people do |t|
      t.boolean :music_access, :default => false
    end
  end
end
