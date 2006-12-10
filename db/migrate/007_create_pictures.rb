class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.column :event_id, :integer
      t.column :person_id, :integer
      t.column :created_at, :datetime
      t.column :cover, :boolean, :default => false
    end
  end

  def self.down
    drop_table :pictures
  end
end
