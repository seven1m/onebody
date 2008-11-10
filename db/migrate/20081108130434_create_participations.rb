class CreateParticipations < ActiveRecord::Migration
  def self.up
    create_table :participation_categories do |t|
      t.string :name, :null => false
      t.text   :description, :null => true
    end
    
    # Populates the participation_categories table with some sample data.
    # TODO - to be removed when participation categories management UI are completed.
    ParticipationCategory.create(:name => "Choir")
    ParticipationCategory.create(:name => "Liturgist")
    ParticipationCategory.create(:name => "Offering")
    ParticipationCategory.create(:name => "Sound System")
    ParticipationCategory.create(:name => "Sunday School")
    ParticipationCategory.create(:name => "Usher")
    ParticipationCategory.create(:name => "Website")

    create_table :participations do |t|
      t.integer :person_id, :null => false
      t.integer :participation_category_id, :null => false
      t.string  :status, :null => false, :default => 'current' # current | pending | completed
      t.timestamps
    end
  end

  def self.down
    drop_table :participation_categories
    drop_table :participations
  end
end
