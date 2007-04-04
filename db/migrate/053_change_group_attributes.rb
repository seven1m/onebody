class ChangeGroupAttributes < ActiveRecord::Migration
  def self.up
    rename_column :groups, :archived, :hidden
  end

  def self.down
    rename_column :groups, :hidden, :archived
  end
end
