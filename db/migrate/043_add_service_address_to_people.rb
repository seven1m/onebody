class AddServiceAddressToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :service_address, :string, :limit => 255
  end

  def self.down
    remove_column :people, :service_address
  end
end
