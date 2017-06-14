class FamilyAuthorizer < ApplicationAuthorizer
  def self.creatable_by?(user)
    user.admin?(:edit_profiles)
  end

  def readable_by?(user)
    # my family
    if resource == user.family && !resource.deleted?
      true
    # visible to everyone
    elsif resource.visible? && !resource.deleted?
      true
    # visible and deleted
    elsif resource.visible? && resource.deleted?
      true if user.admin?(:edit_profiles)
    # invisible and deleted
    elsif !resource.visible? && resource.deleted?
      true if user.admin?(:edit_profiles) && user.admin?(:view_hidden_profiles)
    end
  end

  def updatable_by?(user)
    # my family
    if resource == user.family && user.adult? && !resource.deleted? && !user.account_frozen?
      true
    # admins with edit_profiles privilege
    elsif user.admin?(:edit_profiles)
      # visible to all
      if resource.visible?
        true
      # admin can see hidden people
      elsif user.admin?(:view_hidden_profiles)
        true
      end
    end
  end

  def deletable_by?(user)
    # admins with edit_profiles privilege
    if user.admin?(:edit_profiles)
      # visible to all
      if resource.visible?
        true
      # admin can see hidden people
      elsif user.admin?(:view_hidden_profiles)
        true
      end
    end
  end

  def reorderable_by?(user)
    user.admin?(:edit_profiles)
  end
end
