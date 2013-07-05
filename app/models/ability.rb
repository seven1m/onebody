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
    allow_pages
    allow_attachments
    allow_news_items
    allow_memberships
    disallow_frozen_account
  end

  private

  def allow_people
    can(:read, Person) { |p| admin_or_person_visible(p) and not person_or_family_deleted(p) }
    can :update, @person
    can [:read, :update], Person, family: @person.family, deleted: false if @person.adult? and not @person.family.deleted?
    if @person.admin?(:edit_profiles)
      can(:manage, Person) { |p| admin_or_person_visible(p) }
    end
  end

  def person_or_family_deleted(person)
    person.deleted? or
    (person.family and person.family.deleted?)
  end

  def person_visible(person)
    person.visible? and
    person.visible_to_everyone? and
    person.family.try(:visible?) and
    person.adult_or_consent?
  end

  def admin_or_person_visible(person)
    @person.admin?(:view_hidden_profiles) or
    person_visible(person)
  end

  def allow_families
    can :update, @person.family if @person.adult?
    can :manage, Family if @person.admin?(:edit_profiles)
  end

  def allow_groups
    can :read, Group, hidden: false, private: false
    can :read, Group, memberships: {person: @person}
    can [:update, :destroy], Group, memberships: {person: @person, admin: true}
    can :manage, Group if @person.admin?(:manage_groups)
  end

  def allow_albums
    can :manage, Album, owner_type: 'Person', owner_id: @person.id
    can :read, Album, owner_type: 'Person', owner_id: @person.friend_ids
    can :read, Album, is_public: true
    can :read, Album.join_group_memberships, ['memberships.person_id = ?', @person.id] do |album|
      Group === album.owner and album.owner.memberships.where(person_id: @person.id).any?
    end
    can :manage, Album.join_group_memberships, ['memberships.person_id = ? and memberships.admin = ?', @person.id, true] do |album|
      Group === album.owner and album.owner.memberships.where(person_id: @person.id, admin: true).any?
    end
    can :manage, Album if @person.admin?(:manage_pictures)
  end

  def allow_pictures
    can [:update, :destroy], Picture, person: @person
    can [:update, :destroy], Picture, album: {owner: {memberships: {person: @person, admin: true}}}
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

  def allow_pages
    can :manage, Page if @person.admin?(:edit_pages)
  end

  def allow_attachments
    can [:update, :destroy], Attachment, message: {person: @person}
    can [:update, :destroy], Attachment, group: {memberships: {person: @person, admin: true}}
    can [:update, :destroy], Attachment, message: {group: {memberships: {person: @person, admin: true}}}
    if @person.admin?(:manage_groups)
      can :manage, Attachment do |attachment|
        attachment.group_id # belongs to a group
      end
    end
  end

  def allow_news_items
    can [:update, :destroy], NewsItem, person: @person
    can :manage, NewsItem if @person.admin?(:manage_news)
  end

  def allow_memberships
    can [:update, :destroy], Membership, person: @person
    can [:update, :destroy], Membership, person: {family_id: @person.family_id, deleted: false} if @person.adult?
    can [:update, :destroy], Membership, group: {memberships: {person: @person, admin: true}}
    can :manage, Membership if @person.admin?(:manage_groups) or @person.admin?(:edit_profiles)
  end

  def disallow_frozen_account
    cannot [:update, :destroy], :all if @person.account_frozen?
  end

end
