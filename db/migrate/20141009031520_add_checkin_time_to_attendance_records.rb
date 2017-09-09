class AddCheckinTimeToAttendanceRecords < ActiveRecord::Migration[4.2]
  def change
    change_table :attendance_records do |t|
      t.integer :checkin_time_id
    end
  end
end
