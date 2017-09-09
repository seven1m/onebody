class AddFamilyIdToImportRows < ActiveRecord::Migration[4.2]
  def change
    change_table :import_rows do |t|
      t.belongs_to :family
    end
  end
end
