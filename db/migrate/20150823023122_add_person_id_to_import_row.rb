class AddPersonIdToImportRow < ActiveRecord::Migration
  def change
    change_table :import_rows do |t|
      t.belongs_to :person
    end
  end
end
