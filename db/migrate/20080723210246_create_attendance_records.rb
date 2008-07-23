class CreateAttendanceRecords < ActiveRecord::Migration
  def self.up
    create_table :attendance_records do |t|
      t.integer :site_id
      t.integer :person_id
      t.integer :group_id
      t.datetime :attended_at
      t.timestamps
    end
    change_table :groups do |t|
      t.boolean :attendance, :default => true
    end
  end

  def self.down
    drop_table :attendance_records
    change_table :groups do |t|
      t.remove :attendance
    end
  end
end
