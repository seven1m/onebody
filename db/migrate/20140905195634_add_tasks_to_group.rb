class AddTasksToGroup < ActiveRecord::Migration
  def change
    change_table :groups do |t|
      t.boolean :has_tasks, default: false
    end
  end
end
