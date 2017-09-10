class AddIndexToImportIdOnImportRows < ActiveRecord::Migration[4.2]
  def change
    add_index :import_rows, %i(site_id import_id)
  end
end
