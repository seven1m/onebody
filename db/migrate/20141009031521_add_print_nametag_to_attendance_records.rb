class AddPrintNametagToAttendanceRecords < ActiveRecord::Migration[4.2]
  def change
    change_table :attendance_records do |t|
      t.boolean :print_nametag, :print_extra_nametag
    end
  end
end
