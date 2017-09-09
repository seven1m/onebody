class AddStreamItemGroupIdToStreamItems < ActiveRecord::Migration[4.2]
  def change
    change_table :stream_items do |t|
      t.integer :stream_item_group_id
    end
  end
end
