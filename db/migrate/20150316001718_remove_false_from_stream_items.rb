class RemoveFalseFromStreamItems < ActiveRecord::Migration
  def change
    change_table :stream_items do |t|
      # I have no idea how this got there :-(
      t.remove :false
    end
  end
end
