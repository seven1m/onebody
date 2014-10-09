class AddPrintNametagToAttendanceRecords < ActiveRecord::Migration
  def change
    change_table :attendance_records do |t|
      t.boolean :print_nametag, :print_extra_nametag
    end
  end
end
