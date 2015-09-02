class PersonAuthorizer < ApplicationAuthorizer

  def self.creatable_by?(user)
    user.admin?(:edit_profiles)
  end

  def readable_by?(user)
    # myself
    if resource == user and not deleted?
      true
    # my family and I'm a parent (adult)
    elsif resource.family and resource.family == user.family and user.adult? and not deleted?
      true
    # visible to everyone
    elsif visible? and not deleted?
      true
    # admins with this privilege can view all
    elsif user.admin?(:view_hidden_profiles)
      true
    end
  end

  def updatable_by?(user)
    # myself
    if resource == user and not deleted? and not resource.account_frozen?
      true
    # my family and I'm a parent (adult)
    elsif resource.family and resource.family == user.family and user.adult? and not deleted? and not resource.account_frozen?
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
    if visible? and user.admin?(:edit_profiles)
      true
    # admins with these privileges can see and edit all
    elsif user.admin?(:view_hidden_profiles) and user.admin?(:edit_profiles)
      true
    end
  end

  def deleted?
    resource.deleted? or resource.family.try(:deleted?)
  end

  def visible?
    resource.visible?
  end

end
