class AddIndexToAttendanceRecords < ActiveRecord::Migration
  def self.up
    add_index "attendance_records", ["site_id"],     :name => "index_site_id_on_attendance_records"
    add_index "attendance_records", ["attended_at"], :name => "index_attended_at_on_attendance_records"
    add_index "attendance_records", ["group_id"],    :name => "index_group_id_on_attendance_records"
    add_index "attendance_records", ["person_id"],   :name => "index_person_id_on_attendance_records"
  end

  def self.down
    remove_index :name => "index_site_id_on_attendance_records"
    remove_index :name => "index_admin_id_on_attendance_records"
    remove_index :name => "index_group_id_on_attendance_records"
    remove_index :name => "index_person_id_on_attendance_records"
  end
end
