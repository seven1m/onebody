class IncreaseSizeOfAttachmentContentType < ActiveRecord::Migration
  def change
    change_column :attachments, :content_type, :string, limit: 255
  end
end
