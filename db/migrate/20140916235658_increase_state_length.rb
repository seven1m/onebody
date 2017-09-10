class IncreaseStateLength < ActiveRecord::Migration[4.2]
  def change
    change_column :families, :state, :string
  end
end
