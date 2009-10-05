class AddBarcodeIdChangedToFamilies < ActiveRecord::Migration
  def self.up
    change_table :families do |t|
      t.boolean :barcode_id_changed, :default => false
    end
  end

  def self.down
    change_table :families do |t|
      t.remove :barcode_id_changed
    end
  end
end
