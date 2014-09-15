class AddPositionToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :position, :integer
  end
end
