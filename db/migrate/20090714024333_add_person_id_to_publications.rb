class AddPersonIdToPublications < ActiveRecord::Migration
  def self.up
    change_table :publications do |t|
      t.integer :person_id
    end
  end

  def self.down
    change_table :publications do |t|
      t.remove :person_id
    end
  end
end
