class RenamePersonSequenceToPosition < ActiveRecord::Migration[4.2]
  def change
    rename_column :people, :sequence, :position
  end
end
