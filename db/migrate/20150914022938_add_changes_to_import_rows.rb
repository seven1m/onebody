class AddChangesToImportRows < ActiveRecord::Migration[4.2]
  def change
    change_table :import_rows do |t|
      t.text :attribute_changes
    end
  end
end
