class CheckinMigration < ActiveRecord::Migration
  def self.up
    create_table :checkin_attendance_records do |t|
      t.integer :person_id
      t.integer :site_id
      t.string :barcode_id, :limit => 50
      t.string :first_name, :last_name, :family_name, :age, :limit => 255
      t.string :section, :limit => 255
      t.datetime :in
      t.datetime :out
      t.boolean :void, :default => false
      t.string :can_pick_up, :limit => 100
      t.string :cannot_pick_up, :limit => 100
      t.string :medical_notes, :limit => 200
      t.timestamps
    end
    change_table :people do |t|
      t.string :barcode_id, :limit => 50
      t.string :can_pick_up, :limit => 100
      t.string :cannot_pick_up, :limit => 100
      t.string :medical_notes, :limit => 200
      t.boolean :checkin_access, :default => false
    end
    change_table :admins do |t|
      t.boolean :manage_checkin, :default => false
    end
    Setting.update_from_yaml(File.dirname(__FILE__) + '/settings.yml')
  end
  
  def self.down
    drop_table :checkin_attendance_records
    change_table :people do |t|
      t.remove :barcode_id
      t.remove :can_pick_up
      t.remove :cannot_pick_up
      t.remove :medical_notes
      t.remove :checkin_access
    end
    change_table :admins do |t|
      t.remove :manage_checkin
    end
  end
end
