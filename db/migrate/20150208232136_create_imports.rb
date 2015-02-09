class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.references :site
      t.references :person
      t.string :filename
      t.string :status
      t.integer :success_count, :fail_count
      t.text :mappings
      t.timestamps null: false
    end

    create_table :import_rows do |t|
      t.references :site
      t.references :import
      t.string :status
      t.integer :sequence
      t.string :error_reasons, limit: 1000
    end

    create_table :import_attributes do |t|
      t.references :site
      t.references :import
      t.references :import_row
      t.string :column_name, :model, :name
      t.text :value
      t.integer :sequence
      t.string :error_reasons
    end
  end
end
