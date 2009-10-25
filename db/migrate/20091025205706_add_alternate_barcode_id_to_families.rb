class AddAlternateBarcodeIdToFamilies < ActiveRecord::Migration
  def self.up
    change_table :families do |t|
      t.string :alternate_barcode_id, :limit => 50
    end
  end

  def self.down
    change_table :families do |t|
      t.remove :alternate_barcode_id
    end
  end
end
