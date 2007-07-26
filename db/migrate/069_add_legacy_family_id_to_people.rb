class AddLegacyFamilyIdToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :legacy_family_id, :integer
  end

  def self.down
    remove_column :people, :legacy_family_id
  end
end
