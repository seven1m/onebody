class PersonAuthorizer < ApplicationAuthorizer
  def self.creatable_by?(user)
    user.admin?(:edit_profiles)
  end

  def readable_by?(user)
    # myself
    if resource == user && !deleted?
      true
    # my family and I'm a parent (adult)
    elsif resource.family && resource.family == user.family && user.adult? && !deleted?
      true
    # visible to everyone
    elsif visible? && !deleted?
      true
    # admins with this privilege can view all
    elsif user.admin?(:view_hidden_profiles)
      true
    end
  end

  def updatable_by?(user)
    # myself
    if resource == user && !deleted? && !resource.account_frozen?
      true
    # my family and I'm a parent (adult)
    elsif resource.family && resource.family == user.family && user.adult? && !deleted? && !resource.account_frozen?
      true
    # admins with edit_profiles privilege
    elsif user.admin?(:edit_profiles)
      # visible to all
      if visible?
        true
      # admin can see hidden people
      elsif user.admin?(:view_hidden_profiles)
        true
      end
    end
  end

  def deletable_by?(user)
    # admins with edit_profiles privilege
    if visible? && user.admin?(:edit_profiles)
      true
    # admins with these privileges can see and edit all
    elsif user.admin?(:view_hidden_profiles) && user.admin?(:edit_profiles)
      true
    end
  end

  def deleted?
    resource.deleted? || resource.family.try(:deleted?)
  end

  def visible?
    resource.visible?
  end
end
