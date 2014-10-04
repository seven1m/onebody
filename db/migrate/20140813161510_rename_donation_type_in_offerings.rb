class RenameDonationTypeInOfferings < ActiveRecord::Migration
  def change
    rename_column :offerings, :donation_type, :offering_type
  end
end
