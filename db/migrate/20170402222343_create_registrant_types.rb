class CreateRegistrantTypes < ActiveRecord::Migration
  def change
    create_table :registrant_types do |t|
      t.belongs_to :site, index: true
      t.belongs_to :event, index: true
      t.string :name
      t.text :description
      t.decimal :base_cost
      t.boolean :required, default: false
      t.integer :ordering
      t.integer :flags, null: false, default: 0

      t.timestamps null: false
    end
  end
end
