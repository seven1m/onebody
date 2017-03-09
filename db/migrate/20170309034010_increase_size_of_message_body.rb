class IncreaseSizeOfMessageBody < ActiveRecord::Migration
  def change
    change_column :messages, :body, :text, limit: 16_777_215
    change_column :messages, :html_body, :text, limit: 16_777_215
  end
end
