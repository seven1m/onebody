class RemoveFalseFromStreamItems < ActiveRecord::Migration[4.2]
  def change
    change_table :stream_items do |t|
      # I have no idea how this got there :-(
      t.remove :false
    end
  end
end
