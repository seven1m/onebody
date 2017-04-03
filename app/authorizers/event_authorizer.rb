class EventAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    user.admin?(:manage_event_registrations)
  end

  def updatable_by?(user)
    user.admin?(:manage_event_registrations)
  end

  alias_method :deletable_by?, :updatable_by?
end
