class RemoveNotes < ActiveRecord::Migration
  def change
    remove_reference :comments, :note
    drop_table :notes
  end
end
