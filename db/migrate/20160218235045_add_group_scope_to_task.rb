class AddGroupScopeToTask < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :group_scope, :boolean
  end
end
