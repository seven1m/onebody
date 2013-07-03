class Ability
  include CanCan::Ability

  def initialize(person)

    # person
    can :update, person
    can :update, Person, family: person.family, deleted: false if person.adult?
    can :manage, Person if person.admin?(:edit_profiles)

    # family
    can :update, person.family if person.adult?
    can :manage, Family if person.admin?(:edit_profiles)

    # group
    can [:update, :destroy], Group, memberships: {person: person, admin: true}
    can :manage, Group if person.admin?(:manage_groups)

    # album
    can [:update, :destroy], Album, person: person
    can :manage, Album if person.admin?(:manage_pictures)

  end
end
