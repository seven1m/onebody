class SetStatusDefault < ActiveRecord::Migration
  def change
    change_column_default :people, :status, 0
  end
end
