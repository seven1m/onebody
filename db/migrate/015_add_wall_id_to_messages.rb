class AddWallIdToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :wall_id, :integer
  end

  def self.down
    remove_column :messages, :wall_id
  end
end
