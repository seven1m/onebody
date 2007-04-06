class AddEventToRecipesAndVerses < ActiveRecord::Migration
  def self.up
    add_column :recipes, :event_id, :integer
    add_column :verses, :event_id, :integer
  end

  def self.down
    remove_column :recipes, :event_id
    remove_column :verses, :event_id
  end
end
