class PageAuthorizer < ApplicationAuthorizer

  def readable_by?(user)
    false # TODO
  end

  def updatable_by?(user)
    user.admin?(:edit_pages)
  end

  alias_method :deletable_by?, :updatable_by?

end
