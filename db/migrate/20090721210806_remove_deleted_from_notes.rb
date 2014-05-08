class RemoveDeletedFromNotes < ActiveRecord::Migration
  def self.up
    Site.each { Note.where(deleted: true).each { |n| n.destroy } }
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
