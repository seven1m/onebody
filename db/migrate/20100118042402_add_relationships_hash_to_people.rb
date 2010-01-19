class AddRelationshipsHashToPeople < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.string :relationships_hash, :limit => 40
    end
    Person.reset_column_information
    Site.each do
      Person.all(:conditions => "(select count(id) from relationships where person_id=people.id) > 0").each do |person|
        person.update_relationships_hash
        person.save
      end
    end
  end

  def self.down
    change_table :people do |t|
      t.remove :relationships_hash
    end
  end
end
