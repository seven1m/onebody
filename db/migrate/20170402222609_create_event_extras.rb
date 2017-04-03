class CreateEventExtras < ActiveRecord::Migration
  def change
    create_table :event_extras do |t|
      t.belongs_to :site, index: true
      t.belongs_to :event, index: true
      t.string :kind
      t.string :name
      t.text :description
      t.decimal :cost
      t.integer :available
      t.integer :limit_per
      t.integer :ordering

      t.timestamps null: false
    end
  end
end
