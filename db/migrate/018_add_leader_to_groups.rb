class AddLeaderToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :leader_id, :integer
  end

  def self.down
    remove_column :groups, :leader_id
  end
end
