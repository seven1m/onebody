class PageAuthorizer < ApplicationAuthorizer
  def readable_by?(_user)
    false # TODO
  end

  def updatable_by?(user)
    user.admin?(:edit_pages)
  end

  alias deletable_by? updatable_by?
end
