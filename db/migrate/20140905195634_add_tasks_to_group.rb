class AddTasksToGroup < ActiveRecord::Migration[4.2]
  def change
    change_table :groups do |t|
      t.boolean :has_tasks, default: false
    end
  end
end
