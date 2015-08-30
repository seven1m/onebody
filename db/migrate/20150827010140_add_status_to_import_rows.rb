class AddStatusToImportRows < ActiveRecord::Migration
  def change
    change_table :import_rows do |t|
      t.integer :status
    end
  end
end
