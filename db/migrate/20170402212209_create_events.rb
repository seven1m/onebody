class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.belongs_to :site, index: true
      t.string :name
      t.text :description
      t.timestamp :registration_starts_at
      t.timestamp :registration_ends_at
      t.integer :visibility, default: 1

      t.timestamps null: false
    end
  end
end
