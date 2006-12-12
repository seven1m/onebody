class MoveAnniversaryToPeople < ActiveRecord::Migration
  def self.up
    remove_column :families, :anniversary
    add_column :people, :anniversary, :datetime
  end

  def self.down
    remove_column :people, :anniversary
    add_column :families, :anniversary, :datetime
  end
end
