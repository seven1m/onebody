class AttachmentAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    # on a message I can see
    true if resource.message && user.can_read?(resource.message)
  end

  def deletable_by?(user)
    # attachment on my message
    if resource.message.try(:person) == user
      true
    # message attachment in group and user is admin
    elsif resource.message && resource.message.group.try(:admin?, user)
      true
    end
  end
end
