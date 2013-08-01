class NoteAuthorizer < ApplicationAuthorizer

  def readable_by?(user)
    # no group, person is visible
    if not resource.group and resource.person.readable_by?(user)
      true
    # note in a group, person can see group
    elsif resource.group and resource.group.readable_by?(user)
      true
    end
  end

  def creatable_by?(user)
    # my note
    if resource.person == user
      true
    # group note and user is member
    elsif resource.group and user.member_of?(resource.group)
      true
    # admin with manage_notes privilege
    elsif user.admin?(:manage_notes)
      true
    end
  end

  def updatable_by?(user)
    resource.person_id == user.id or user.admin?(:manage_notes)
  end

  alias_method :deletable_by?, :updatable_by?

end
