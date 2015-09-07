class DocumentFolderGroup < ActiveRecord::Base
  belongs_to :document_folder
  belongs_to :group
  scope_by_site_id
end
