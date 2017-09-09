class AddOutcomesToImportRows < ActiveRecord::Migration[4.2]
  def change
    change_table :import_rows do |t|
      t.boolean :created_person, default: false
      t.boolean :created_family, default: false
      t.boolean :updated_person, default: false
      t.boolean :updated_family, default: false
    end
  end
end
