class AddCreatedAtToMigrations < ActiveRecord::Migration
  def self.up
    add_column :sessions, :created_at, :datetime
  end

  def self.down
    remove_column :sessions, :created_at
  end
end
