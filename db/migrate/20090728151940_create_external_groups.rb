class CreateExternalGroups < ActiveRecord::Migration
  def self.up
    create_table :external_groups do |t|
      t.string :name, :limit => 255
      t.string :category, :limit => 1000
      t.integer :external_id
      t.integer :site_id
      t.timestamps
    end
  end

  def self.down
    drop_table :external_groups
  end
end
