class IncreaseSizeOfStreamItemBody < ActiveRecord::Migration[4.2]
  def change
    change_column :stream_items, :body, :text, limit: 16_777_215
  end
end
