class AttachmentAuthorizer < ApplicationAuthorizer

  def readable_by?(user)
    false # TODO
  end

  def deletable_by?(user)
    # attachment on my message
    if resource.message.try(:person) == user
      true
    # group attachment and user is admin
    elsif resource.group.try(:admin?, user)
      true
    # message attachment in group and user is admin
    elsif resource.message.try(:group).try(:admin?, user)
      true
    end
  end

end
