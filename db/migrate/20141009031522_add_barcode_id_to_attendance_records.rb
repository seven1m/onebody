class AddBarcodeIdToAttendanceRecords < ActiveRecord::Migration[4.2]
  def change
    change_table :attendance_records do |t|
      t.string :barcode_id, limit: 50
    end
  end
end
