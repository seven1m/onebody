class AddManyToManyVersesEventsRemoveEventIdFromVerses < ActiveRecord::Migration
  def self.up
    remove_column :verses, :event_id
    
    create_table :events_verses, :id => false do |t|
      t.column :event_id, :integer
      t.column :verse_id, :integer
    end
  end

  def self.down
    add_column :verses, :event_id, :integer
  end
end
