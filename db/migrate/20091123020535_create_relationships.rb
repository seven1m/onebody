class CreateRelationships < ActiveRecord::Migration
  def self.up
    create_table :relationships do |t|
      t.integer :person_id
      t.integer :related_id
      t.string :name, :limit => 255
      t.string :other_name, :limit => 255
      t.integer :site_id
      t.timestamps
    end
  end

  def self.down
    drop_table :relationships
  end
end
