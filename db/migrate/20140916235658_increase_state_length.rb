class IncreaseStateLength < ActiveRecord::Migration
  def change
    change_column :families, :state, :string
  end
end
