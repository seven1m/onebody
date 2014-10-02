class AddCountry < ActiveRecord::Migration
  def change
    change_table :families do |t|
      t.string :country, limit: 2
    end
  end
end
