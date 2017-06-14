class CommentAuthorizer < ApplicationAuthorizer
  def readable_by?(_user)
    false # TODO
  end

  def updatable_by?(user)
    # my comment
    if resource.person == user
      true
    # admin with manage_comments privilege
    elsif user.admin?(:manage_comments)
      true
    end
  end

  alias deletable_by? updatable_by?
end
