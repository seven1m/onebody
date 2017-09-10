class CreateDocumentFolderGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :document_folder_groups do |t|
      t.references :document_folder
      t.references :group
      t.datetime :created_at
    end

    add_index :document_folder_groups, :document_folder_id
    add_index :document_folder_groups, :group_id
  end
end
