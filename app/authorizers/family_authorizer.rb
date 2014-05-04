class FamilyAuthorizer < ApplicationAuthorizer

  def self.creatable_by?(user)
    user.admin?(:edit_profiles)
  end

  def readable_by?(user)
    false # TODO
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

end
