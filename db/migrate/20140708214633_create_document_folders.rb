class CreateDocumentFolders < ActiveRecord::Migration
  def change
    create_table :document_folders do |t|
      t.string :name
      t.string :description, limit: 1000
      t.boolean :hidden, default: false
      t.integer :folder_id
      t.string :parent_folder_ids, limit: 1000
      t.string :path, limit: 1000

      t.timestamps
    end
  end
end
