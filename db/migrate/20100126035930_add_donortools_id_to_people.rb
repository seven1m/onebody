class AddDonortoolsIdToPeople < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.integer :donortools_id
      t.boolean :synced_to_donortools, :default => false
    end
  end

  def self.down
    change_table :people do |t|
      t.remove :donortools_id
      t.remove :synced_to_donortools
    end
  end
end
