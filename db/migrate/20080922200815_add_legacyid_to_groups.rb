class AddLegacyidToGroups < ActiveRecord::Migration
  
  def self.up
    add_column :groups, :legacy_id, :integer
  end

  def self.down
    remove_column :groups, :legacy_id
  end
  
end
