class SetStatusDefault < ActiveRecord::Migration[4.2]
  def change
    change_column_default :people, :status, 0
  end
end
