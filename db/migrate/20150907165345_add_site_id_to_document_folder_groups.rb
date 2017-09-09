class AddSiteIdToDocumentFolderGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :document_folder_groups, :site_id, :integer
    Site.each do
      DocumentFolderGroup.connection.execute(
        'update document_folder_groups set site_id = (select site_id from groups where id = document_folder_groups.id);'
      )
    end
  end

  def down
    remove_column :document_folder_groups, :site_id
  end
end
