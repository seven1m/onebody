class RoleAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    # pubic, visible-to-everyone role
    if !(resource.hidden? || resource.private?)
      true
    # user is a member of the role
    elsif user.member_of?(resource)
      true
    # user is admin who manages roles
    elsif user.admin?(:manage_roles)
      true
    end
  end

  def updatable_by?(user)
    # user is an admin of the role
    if user.member_of?(resource) && resource.admin?(user)
      true
    # user is global admin with manage_roles privilege
    elsif user.admin?(:manage_roles)
      true
    end
  end

  alias deletable_by? updatable_by?
end
