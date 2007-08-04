class AddRecentlyPrivacyToPeopleAndFamilies < ActiveRecord::Migration
  def self.up
    add_column :people, :share_activity, :boolean
    add_column :families, :share_activity, :boolean, :default => true
  end

  def self.down
    remove_column :people, :share_activity
    remove_column :families, :share_activity
  end
end
