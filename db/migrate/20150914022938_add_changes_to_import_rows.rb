class AddChangesToImportRows < ActiveRecord::Migration
  def change
    change_table :import_rows do |t|
      t.text :attribute_changes
    end
  end
end
