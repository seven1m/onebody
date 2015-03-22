class DocumentAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    if user.admin?(:manage_documents)
      true
    elsif resource.hidden?
      false
    elsif (ids = resource.parent_folder_group_ids).any?
      (ids & user.group_ids).any?
    else
      true
    end
  end
end
