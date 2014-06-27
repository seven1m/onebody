class AddBarcodeAssignedAtToFamilies < ActiveRecord::Migration
  def self.up
    change_table :families do |t|
      t.datetime :barcode_assigned_at
    end
    Family.reset_column_information
    Site.each do
      Family.where("barcode_id is not null and barcode_id != ''").each do |family|
        last_log_item = LogItem.where(
          "loggable_type = 'Family' and loggable_id = ? and object_changes like '%barcode_id%'", family.id
        ).order(
          'created_at desc'
        ).detect do |log_item|
          log_item.object_changes['barcode_id'][1].to_s != '' rescue false
        end
        if last_log_item
          family.update_attributes!(:barcode_assigned_at => last_log_item.created_at)
        end
      end
    end
  end

  def self.down
    change_table :families do |t|
      t.remove :barcode_assigned_at
    end
  end
end
