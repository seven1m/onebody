class AddFamilyIdToImportRows < ActiveRecord::Migration
  def change
    change_table :import_rows do |t|
      t.belongs_to :family
    end
  end
end
