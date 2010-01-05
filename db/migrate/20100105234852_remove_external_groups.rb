class RemoveExternalGroups < ActiveRecord::Migration
  def self.up
    drop_table :external_groups
    change_table :attendance_records do |t|
      t.remove :external_group_id
    end
  end

  def self.down
    create_table :external_groups do |t|
      t.string :name, :limit => 255
      t.string :category, :limit => 1000
      t.integer :external_id
      t.integer :site_id
      t.timestamps
    end
    change_table :attendance_records do |t|
      t.integer :external_group_id
    end
  end
end
