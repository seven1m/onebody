class AddBarcodeIdToFamilies < ActiveRecord::Migration
  def self.up
    change_table :families do |t|
      t.string :barcode_id, :limit => 50
    end
  end

  def self.down
    change_table :families do |t|
      t.remove :barcode_id
    end
  end
end
