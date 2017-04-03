class CreateRegistrantReleases < ActiveRecord::Migration
  def change
    create_table :registrant_releases do |t|
      t.string :name
      t.text :description
      t.string :url
      t.belongs_to :event, index: true
      t.belongs_to :registrant_type, index: true
      t.boolean :required, default: true
      t.integer :ordering

      t.timestamps null: false
    end
  end
end
