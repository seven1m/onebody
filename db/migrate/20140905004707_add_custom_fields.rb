class AddCustomFields < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_fields do |t|
      t.integer :site_id
      t.string :name, limit: 50
      t.string :format, limit: 10
      t.timestamps
    end

    create_table :custom_field_values do |t|
      t.integer :site_id
      t.integer :field_id
      t.belongs_to :object, polymorphic: true
      t.string :value
    end
  end
end
