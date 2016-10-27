class AddIndexToImportIdOnImportRows < ActiveRecord::Migration
  def change
    add_index :import_rows, %i(site_id import_id)
  end
end
