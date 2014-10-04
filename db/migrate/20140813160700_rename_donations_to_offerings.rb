class RenameDonationsToOfferings < ActiveRecord::Migration
  def change
    rename_table :donations, :offerings
  end
end
