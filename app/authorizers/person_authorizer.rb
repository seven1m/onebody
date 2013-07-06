class PersonAuthorizer < ApplicationAuthorizer

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

  #def allow_people
    #can :update, @person
    #can [:read, :update], Person, family: @person.family, deleted: false if @person.adult? and not @person.family.deleted?
    #if @person.admin?(:edit_profiles)
      #can(:manage, Person) { |p| admin_or_person_visible(p) }
    #end
  #end

  def deleted?
    resource.deleted? or resource.family.try(:deleted?)
  end

  def visible?
    resource.visible? and
    resource.visible_to_everyone? and
    resource.adult_or_consent? and
    resource.family.try(:visible?)
  end

end
