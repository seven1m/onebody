class UpdateComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :event_id, :integer
    add_column :comments, :recipe_id, :integer
  end

  def self.down
    remove_column :comments, :event_id
    remove_column :comments, :recipe_id
  end
end
