class RenamePeopleFrozen < ActiveRecord::Migration
  def self.up
    rename_column :people, :frozen, :account_frozen
  end

  def self.down
    rename_column :people, :account_frozen, :frozen
  end
end
