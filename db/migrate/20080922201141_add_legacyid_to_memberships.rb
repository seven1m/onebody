class AddLegacyidToMemberships < ActiveRecord::Migration
  
  def self.up
    add_column :memberships, :legacy_id, :integer
  end

  def self.down
    remove_column :memberships, :legacy_id
  end
  
end
