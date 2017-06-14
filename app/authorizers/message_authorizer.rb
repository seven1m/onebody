class MessageAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    # message is from me
    if resource.person && resource.person == user
      true
    # message is to me
    elsif resource.to && resource.to == user
      true
    # message in a group I'm a member of
    elsif resource.group && user.member_of?(resource.group)
      true
    end
  end

  def creatable_by?(user)
    # first make sure a reply isn't on a message I can't see
    return false if resource.parent && !user.can_read?(resource.parent)
    # message in a group and I'm a member or admin
    if resource.group && resource.group.can_send?(user)
      true
    # message to a person and I can see that person and they have messaging enabled
    elsif resource.to && user.can_read?(resource.to) && resource.to.messages_enabled?
      true
    end
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

  alias deletable_by? updatable_by?

  def self.readable_by(user, scope = Message.all)
    if user.admin?(:manage_pictures)
      scope
    else
      scope.where(
        "(owner_type = 'Person' and owner_id in (?)) or " \
        "(owner_type = 'Group' and owner_id in (?)) or " \
        'is_public = ?',
        [user.id] + user.friend_ids,
        user.group_ids,
        true
      )
    end
  end
end
