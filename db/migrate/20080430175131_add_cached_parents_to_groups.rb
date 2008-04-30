class AddCachedParentsToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :cached_parents, :text
    add_index :people, :classes
    Site.each { Group.update_cached_parents }
  end

  def self.down
    remove_column :groups, :cached_parents
    remove_index :people, :classes
  end
end
