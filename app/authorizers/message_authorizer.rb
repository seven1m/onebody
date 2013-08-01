class MessageAuthorizer < ApplicationAuthorizer

  def readable_by?(user)
    false # TODO
  end

  def updatable_by?(user)
    # my message
    if resource.person == user
      true
    # message in a group and user is group admin
    elsif resource.group.try(:admin?, user)
      true
    end
  end

  alias_method :deletable_by?, :updatable_by?

end
