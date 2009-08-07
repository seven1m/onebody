class AddExternalGroupIdToAttendanceRecords < ActiveRecord::Migration
  def self.up
    change_table :attendance_records do |t|
      t.integer :external_group_id
    end
  end

  def self.down
    change_table :attendance_records do |t|
      t.remove :external_group_id
    end
  end
end
