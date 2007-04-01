class AddVisibleToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :visible, :boolean, :default => true
  end

  def self.down
    remove_column :people, :visible
  end
end
