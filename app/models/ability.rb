class Ability
  include CanCan::Ability

  def initialize(person)
    @person = person
    allow_people
    allow_families
    allow_groups
    allow_albums
    allow_messages
    allow_prayer_requests
  end

  private

  def allow_people
    can :update, @person
    can :update, Person, family: @person.family, deleted: false if @person.adult?
    can :manage, Person if @person.admin?(:edit_profiles)
  end

  def allow_families
    can :update, @person.family if @person.adult?
    can :manage, Family if @person.admin?(:edit_profiles)
  end

  def allow_groups
    can [:update, :destroy], Group, memberships: {person: @person, admin: true}
    can :manage, Group if @person.admin?(:manage_groups)
  end

  def allow_albums
    can [:update, :destroy], Album, person: @person
    can :manage, Album if @person.admin?(:manage_pictures)
  end

  def allow_messages
    can [:update, :destroy], Message, person: @person
    can [:update, :destroy], Message, group: {memberships: {person: @person, admin: true}}
    if @person.admin?(:manage_groups)
      can :manage, Message do |message|
        message.group_id # belongs to a group
      end
    end
  end

  def allow_prayer_requests
    can [:update, :destroy], PrayerRequest, person: @person
    can [:update, :destroy], PrayerRequest, group: {memberships: {person: @person, admin: true}}
    can :manage, PrayerRequest if @person.admin?(:manage_groups)
  end

end
