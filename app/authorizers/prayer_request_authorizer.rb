class PrayerRequestAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    if resource.person == user
      true
    elsif resource.group && user.member_of?(resource.group)
      true
    end
  end

  def creatable_by?(user)
    if resource.group && user.member_of?(resource.group) && resource.group.prayer?
      true
    end
  end

  def updatable_by?(user)
    # my prayer request
    if resource.person == user
      true
    # group admin
    elsif resource.group.try(:admin?, user)
      true
    end
  end

  alias deletable_by? updatable_by?

  def self.readable_for_group_by_user(group, user)
    if user.member_of?(group)
      group.prayer_requests
    else
      group.prayer_requests.none
    end
  end
end
