class AddIncompleteTasksCountToPeople < ActiveRecord::Migration
  def change
    add_column :people, :incomplete_tasks_count, :integer, default: 0
  end
end
