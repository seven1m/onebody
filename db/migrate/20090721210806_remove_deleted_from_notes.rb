class RemoveDeletedFromNotes < ActiveRecord::Migration
  def self.up
    change_table :notes do |t|
      t.remove :deleted
    end
  end

  def self.down
    change_table :notes do |t|
      t.boolean :deleted, :default => false
    end
  end
end
