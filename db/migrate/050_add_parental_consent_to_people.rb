class AddParentalConsentToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :parental_consent_at, :datetime
  end

  def self.down
    remove_column :people, :parental_consent_at
  end
end
