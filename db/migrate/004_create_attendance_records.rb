class CreateAttendanceRecords < ActiveRecord::Migration
  def self.up
    create_table :attendance_records do |t|
      t.integer :person_id
      t.string :barcode_id, :limit => 50
      t.string :first_name, :last_name, :family_name, :age, :limit => 255
      t.string :section, :limit => 255
      t.datetime :in
      t.datetime :out
      t.boolean :void, :default => false
      t.timestamps
    end
    add_column :people, :barcode_id, :string, :limit => 50
    add_column :people, :can_pick_up, :string, :limit => 100
    add_column :people, :cannot_pick_up, :string, :limit => 100
    add_column :people, :medical_notes, :string, :limit => 200
    add_column :people, :checkin_access, :boolean, :default => false
    add_column :admins, :manage_checkin, :boolean, :default => false
    Setting.update_from_yaml(File.join(RAILS_ROOT, "test/fixtures/settings.yml"))
  end

  def self.down
    drop_table :attendance_records
    remove_column :people, :barcode_id
    remove_column :people, :can_pick_up
    remove_column :people, :cannot_pick_up
    remove_column :people, :medical_notes
    remove_column :people, :checkin_access
    remove_column :admins, :manage_checkin
  end
end
