class AttachmentAuthorizer < ApplicationAuthorizer

  def readable_by?(user)
    # on a message I can see
    if resource.message and user.can_read?(resource.message)
      true
    # on a group I am a member of
    elsif resource.group and user.member_of?(resource.group)
      true
    end
  end

  def creatable_by?(user)
    if resource.group and resource.group.admin?(user)
      true
    end
  end

  def deletable_by?(user)
    # attachment on my message
    if resource.message.try(:person) == user
      true
    # group attachment and user is admin
    elsif resource.group and resource.group.admin?(user)
      true
    # message attachment in group and user is admin
    elsif resource.message and resource.message.group.try(:admin?, user)
      true
    end
  end

end
