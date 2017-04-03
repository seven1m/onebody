class CreateRegistrants < ActiveRecord::Migration
  def change
    create_table :registrants do |t|
      t.belongs_to :site, index: true
      t.belongs_to :registration, index: true
      t.belongs_to :person, index: true
      t.belongs_to :registrant_type
      t.string :first_name
      t.string :last_name
      t.text :contact_info

      t.timestamps null: false
    end
  end
end
