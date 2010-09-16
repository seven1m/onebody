class UpdateRelationshipsHash < ActiveRecord::Migration
  def self.up
    Site.each do
      # only update those without any relationships
      Person.all(:conditions => "(select count(id) from relationships where person_id=people.id) = 0").each do |person|
        person.update_relationships_hash
        person.save
      end
    end
  end

  def self.down
  end
end
