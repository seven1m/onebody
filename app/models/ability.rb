class Ability
  include CanCan::Ability

  def initialize(person)
    @person = person
    allow_people
    allow_families
    allow_groups
    allow_albums
    allow_pictures
    allow_messages
    allow_notes
    allow_prayer_requests
    allow_comments
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
    can [:update, :destroy], Album, group: {memberships: {person: @person, admin: true}}
    can :manage, Album if @person.admin?(:manage_pictures)
  end

  def allow_pictures
    can [:update, :destroy], Picture, person: @person
    can [:update, :destroy], Picture, album: {group: {memberships: {person: @person, admin: true}}}
    can :manage, Picture if @person.admin?(:manage_pictures)
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

  def allow_notes
    can [:update, :destroy], Note, person: @person
    can :manage, Note if @person.admin?(:manage_notes)
  end

  def allow_prayer_requests
    can [:update, :destroy], PrayerRequest, person: @person
    can [:update, :destroy], PrayerRequest, group: {memberships: {person: @person, admin: true}}
    can :manage, PrayerRequest if @person.admin?(:manage_groups)
  end

  def allow_comments
    can [:update, :destroy], Comment, person: @person
    can :manage, Comment if @person.admin?(:manage_comments)
  end

end
