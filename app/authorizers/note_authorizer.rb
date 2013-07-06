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

  def updatable_by?(user)
    resource.person_id == user.id or user.admin?(:manage_notes)
  end

  alias_method :deletable_by?, :updatable_by?

end
