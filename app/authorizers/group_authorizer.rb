class GroupAuthorizer < ApplicationAuthorizer

  def readable_by?(user)
    # pubic, visible-to-everyone group
    if not (resource.hidden? or resource.private?)
      true
    # user is a member of the group
    elsif user.member_of?(resource)
      true
    end
  end

  def updatable_by?(user)
    # user is an admin of the group
    if user.member_of?(resource) and resource.admin?(user)
      true
    # user is global admin with manage_groups privilege
    elsif user.admin?(:manage_groups)
      true
    end
  end

  alias_method :deletable_by?, :updatable_by?

end
