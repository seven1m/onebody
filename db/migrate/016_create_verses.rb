class CreateVerses < ActiveRecord::Migration
  def self.up
    create_table :verses do |t|
      t.column :reference, :string, :limit => 50
      t.column :text, :text
      t.column :translation, :string, :limit => 10
      t.column :created_at, :datetime
    end
    
    create_table :people_verses, :id => false do |t|
      t.column :person_id, :integer
      t.column :verse_id, :integer
    end
  end

  def self.down
    drop_table :verses
    drop_table :people_verses
  end
end
