class AddStatusToImportRows < ActiveRecord::Migration[4.2]
  def change
    change_table :import_rows do |t|
      t.integer :status
    end
  end
end
