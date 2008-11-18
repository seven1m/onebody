class CreateParticipations < ActiveRecord::Migration
  def self.up
    create_table :participation_categories do |t|
      t.string  :name, :null => false
      t.text    :description, :null => true
      t.integer :site_id
    end
    
    create_table :participations do |t|
      t.integer :person_id, :null => false
      t.integer :participation_category_id, :null => false
      t.string  :status, :null => false, :default => 'current' # current | pending | completed
      t.integer :site_id
      t.timestamps
    end
  end

  def self.down
    drop_table :participation_categories
    drop_table :participations
  end
end
