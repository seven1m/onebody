class CreateDonationTransactions < ActiveRecord::Migration
  def change
    create_table :donation_transactions do |t|
      t.integer :user_id
      t.integer :amount
      t.string :transaction_id
      t.string :transaction_email

      t.timestamps
    end
  end
end
