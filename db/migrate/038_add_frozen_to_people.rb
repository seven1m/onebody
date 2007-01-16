class AddFrozenToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :frozen, :boolean, :default => false
  end

  def self.down
    remove_column :people, :frozen
  end
end
