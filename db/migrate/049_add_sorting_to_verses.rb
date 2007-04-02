class AddSortingToVerses < ActiveRecord::Migration
  def self.up
    add_column :verses, :book, :integer
    add_column :verses, :chapter, :integer
    add_column :verses, :verse, :integer
    Verse.find(:all).each do |verse|
      verse.update_sortables
      verse.save
    end
  end

  def self.down
    remove_column :verses, :book
    remove_column :verses, :chapter
    remove_column :verses, :verse
  end
end
