class CreateRegistrationExtras < ActiveRecord::Migration
  def change
    create_table :registration_extras do |t|
      t.belongs_to :site, index: true
      t.string :object_type, index: true
      t.integer :object_id, index: true
      t.integer :count
      t.decimal :total_cost

      t.timestamps null: false
    end
  end
end
