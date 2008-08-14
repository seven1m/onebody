class RenameLogItemChanges < ActiveRecord::Migration
  def self.up
    change_table :log_items do |t|
      t.rename :changes, :object_changes rescue nil
    end
  end

  def self.down
  end
end
