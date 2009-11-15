class CreateSyncs < ActiveRecord::Migration
  def self.up
    create_table :syncs do |t|
      t.integer :site_id
      t.integer :person_id
      t.boolean :complete, :default => false
      t.string :status, :limit => 50
      t.timestamps
    end
  end

  def self.down
    drop_table :syncs
  end
end
