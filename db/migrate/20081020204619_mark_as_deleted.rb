class MarkAsDeleted < ActiveRecord::Migration
  def self.up
    add_column :people, :deleted, :boolean, :default => false
    add_column :families, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :people, :deleted
    remove_column :families, :deleted
  end
end
