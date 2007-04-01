class AddVisibleToFamilies < ActiveRecord::Migration
  def self.up
    add_column :families, :visible, :boolean, :default => true
  end

  def self.down
    remove_column :families, :visible
  end
end
