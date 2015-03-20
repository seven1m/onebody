class DocumentFolderAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    if user.admin?(:manage_documents)
      true
    elsif resource.hidden?
      false
    elsif resource.group_ids.any?
      (resource.group_ids & user.group_ids).any?
    else
      true
    end
  end

  def self.readable_by(user, scope = Album.all)
    if user.admin?(:manage_documents)
      scope
    else
      scope
        .active
        .joins('left join document_folder_groups dfg on dfg.document_folder_id = document_folders.id')
        .where('dfg.group_id is null or dfg.group_id in (?)', user.group_ids)
    end
  end
end
