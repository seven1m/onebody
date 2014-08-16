class AddFieldsToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :name, :string
    add_money :donations, :amount
  end
end
