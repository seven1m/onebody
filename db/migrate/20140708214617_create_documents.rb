class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :name
      t.string :description, limit: 1000
      t.integer :folder_id
      t.string :file_file_name, :file_content_type
      t.string :file_fingerprint, :limit => 50
      t.integer :file_file_size
      t.datetime :file_updated_at

      t.timestamps
    end
  end
end
