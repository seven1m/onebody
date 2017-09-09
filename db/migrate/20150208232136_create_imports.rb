class CreateImports < ActiveRecord::Migration[4.2]
  def change
    create_table :imports do |t|
      t.references :site
      t.references :person
      t.string :filename, null: false
      t.integer :status, null: false
      t.string :error_message
      t.integer :success_count, :fail_count, null: false, default: 0
      t.string :importable_type, limit: 50, null: false
      t.text :mappings
      t.integer :match_strategy
      t.timestamps null: false
      t.datetime :completed_at
    end

    create_table :import_rows do |t|
      t.references :site
      t.references :import
      t.integer :sequence, null: false
      t.string :error_reasons, limit: 1000
    end

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
