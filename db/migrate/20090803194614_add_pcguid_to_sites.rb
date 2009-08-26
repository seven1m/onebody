class AddPcguidToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :external_guid, :string, :default => "0"
  end

  def self.down
    remove_column :sites, :external_guid
  end
end
