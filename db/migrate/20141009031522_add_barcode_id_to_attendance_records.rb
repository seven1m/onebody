class AddBarcodeIdToAttendanceRecords < ActiveRecord::Migration
  def change
    change_table :attendance_records do |t|
      t.string :barcode_id, limit: 50
    end
  end
end
