class NewsItemAuthorizer < ApplicationAuthorizer

  def readable_by?(user)
    false # TODO
  end

  def updatable_by?(user)
    # my news item
    if resource.person == user
      true
    # admin with manage_news privilege
    elsif user.admin?(:manage_news)
      true
    end
  end

  alias_method :deletable_by?, :updatable_by?

end
