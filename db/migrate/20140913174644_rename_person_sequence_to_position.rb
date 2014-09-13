class RenamePersonSequenceToPosition < ActiveRecord::Migration
  def change
    rename_column :people, :sequence, :position
  end
end
