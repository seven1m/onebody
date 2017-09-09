class AddPositionToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :position, :integer
  end
end
