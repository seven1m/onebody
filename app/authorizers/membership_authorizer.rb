class MembershipAuthorizer < ApplicationAuthorizer
  def readable_by?(_user)
    false # TODO
  end

  def creatable_by?(user)
    if user.can_update?(resource.group)
      true
    elsif resource.group && !resource.group.approval_required_to_join?
      true
    end
  end

  def updatable_by?(user)
    # my membership
    if resource.person == user
      true
    # someone in my family and I'm an adult
    elsif resource.person.try(:family) == user.family && user.adult?
      true
    # group admin
    elsif resource.group.try(:admin?, user)
      true
    # admin with edit_profiles privilege
    elsif user.admin?(:edit_profiles)
      true
    end
  end

  alias deletable_by? updatable_by?
end
