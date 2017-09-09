class SerializeAttributesOnImportRows < ActiveRecord::Migration[4.2]
  def change
    change_table :import_rows do |t|
      t.text :import_attributes
    end

    revert do
      create_table :import_attributes do |t|
        t.references :site
        t.references :import
        t.references :import_row
        t.string :name, null: false
        t.text :value
        t.integer :sequence, null: false
        t.string :error_reasons
      end
    end
  end
end
