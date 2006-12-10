class CreatePublications < ActiveRecord::Migration
  def self.up
    create_table :publications do |t|
      t.column :name, :string, :limit => 255
      t.column :description, :text
      t.column :created_at, :datetime
      t.column :file, :string, :limit => 255
    end
  end

  def self.down
    drop_table :publications
  end
end
