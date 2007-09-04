class AddParentFeatureToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :parents_of, :integer
  end

  def self.down
    remove_column :groups, :parents_of
  end
end
