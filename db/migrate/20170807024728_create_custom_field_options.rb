class CreateCustomFieldOptions < ActiveRecord::Migration
  def change
    create_table :custom_field_options do |t|
      t.integer :site_id, null: false
      t.integer :field_id, null: false
      t.string :label, limit: 1000

      t.timestamps null: false
    end
  end
end
