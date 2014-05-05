class PrayerRequestAuthorizer < ApplicationAuthorizer

  def readable_by?(user)
    false # TODO
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

  alias_method :deletable_by?, :updatable_by?

end
