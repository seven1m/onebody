class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.references :site
      t.references :person
      t.string :filename
      t.integer :status
      t.integer :success_count, :fail_count, default: 0
      t.text :mappings
      t.timestamps null: false
    end

    create_table :import_rows do |t|
      t.references :site
      t.references :import
      t.integer :status
      t.integer :sequence
      t.string :error_reasons, limit: 1000
    end

    create_table :import_attributes do |t|
      t.references :site
      t.references :import
      t.references :import_row
      t.string :name
      t.text :value
      t.integer :sequence
      t.string :error_reasons
    end
  end
end
