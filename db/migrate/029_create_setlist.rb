class CreateSetlist < ActiveRecord::Migration
  def self.up
    create_table :setlists do |t|
      t.column :start, :datetime
      t.column :person_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :setlists
  end
end
