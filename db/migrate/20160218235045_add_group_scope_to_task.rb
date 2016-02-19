class AddGroupScopeToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :group_scope, :boolean
  end
end
