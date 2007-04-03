class ChangeParentalConsentOnPeople < ActiveRecord::Migration
  def self.up
    remove_column :people, :parental_consent_at
    add_column :people, :parental_consent, :string, :limit => 255
  end

  def self.down
    remove_column :people, :parental_consent
    add_column :people, :parental_consent_at, :datetime
  end
end
