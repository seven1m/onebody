class IncreaseSizeOfStreamItemBody < ActiveRecord::Migration
  def change
    change_column :stream_items, :body, :text, limit: 16_777_215
  end
end
