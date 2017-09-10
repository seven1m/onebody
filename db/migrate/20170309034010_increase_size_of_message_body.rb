class IncreaseSizeOfMessageBody < ActiveRecord::Migration[4.2]
  def change
    change_column :messages, :body, :text, limit: 16_777_215
    change_column :messages, :html_body, :text, limit: 16_777_215
  end
end
