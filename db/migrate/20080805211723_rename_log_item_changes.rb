class RenameLogItemChanges < ActiveRecord::Migration
  def self.up
    change_table :log_items do |t|
      t.rename :changes, :object_changes
    end
  end

  def self.down
    change_table :log_items do |t|
      t.rename :object_changes, :changes
    end
  end
end
