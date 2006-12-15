class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column :verse_id, :integer
      t.column :person_id, :integer
      t.column :text, :text
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :comments
  end
end
