class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.column :person_id, :integer
      t.column :name, :string, :limit => 255
      t.column :description, :text
      t.column :when, :datetime
      t.column :created_at, :datetime
      t.column :open, :boolean, :default => false
      t.column :admins, :text
    end
  end

  def self.down
    drop_table :events
  end
end
