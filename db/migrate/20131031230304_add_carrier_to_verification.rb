class AddCarrierToVerification < ActiveRecord::Migration
  def change
    change_table :verifications do |t|
      t.string :carrier, limit: 100
    end
  end
end
