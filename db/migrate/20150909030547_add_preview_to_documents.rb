class AddPreviewToDocuments < ActiveRecord::Migration[4.2]
  def change
    change_table :documents do |t|
      t.string 'preview_file_name', limit: 255
      t.string 'preview_content_type', limit: 255
      t.string 'preview_fingerprint', limit: 50
      t.integer 'preview_file_size', limit: 4
      t.datetime 'preview_updated_at'
    end
  end
end
