class CreateDonations < ActiveRecord::Migration
  def change
    create_table :donations do |t|
      t.date :date
      t.references :person, index: true
      t.references :family, index: true
      t.string :type

      t.timestamps
    end
  end
end
