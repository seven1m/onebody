class AddCheckinTimeToAttendanceRecords < ActiveRecord::Migration
  def change
    change_table :attendance_records do |t|
      t.integer :checkin_time_id
    end
  end
end
