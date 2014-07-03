class FamilyAuthorizer < ApplicationAuthorizer

  def self.creatable_by?(user)
    user.admin?(:edit_profiles)
  end

  def readable_by?(user)
    # my family
    if resource == user.family and not resource.deleted?
      true
    # visible to everyone
    elsif resource.visible? and not resource.deleted?
      true
    # visible and deleted
    elsif resource.visible? and resource.deleted?
      true if user.admin?(:edit_profiles)
    # invisible and deleted
    elsif not resource.visible? and resource.deleted?
      true if user.admin?(:edit_profiles) and user.admin?(:view_hidden_profiles)
    end
  end

  def updatable_by?(user)
    # my family
    if resource == user.family and user.adult? and not resource.deleted? and not user.account_frozen?
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
