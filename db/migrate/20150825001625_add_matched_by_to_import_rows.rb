class AddMatchedByToImportRows < ActiveRecord::Migration[4.2]
  def change
    change_table :import_rows do |t|
      t.integer :matched_person_by
      t.integer :matched_family_by
    end
  end
end
