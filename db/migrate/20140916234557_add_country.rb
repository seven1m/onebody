class AddCountry < ActiveRecord::Migration[4.2]
  def change
    change_table :families do |t|
      t.string :country, limit: 2
    end
  end
end
