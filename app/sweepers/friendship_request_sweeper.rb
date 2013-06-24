class FriendshipRequestSweeper < ActionController::Caching::Sweeper
  observe FriendshipRequest

  def expire_notice(record)
    expire_fragment(controller: 'streams', action: 'show', for: record.person_id, fragment: 'friendship_requests')
    expire_fragment(controller: 'streams', action: 'show', for: record.from_id,   fragment: 'friendship_requests')
  end

  def after_save(record)
    expire_notice(record)
  end

  def after_destroy(record)
    expire_notice(record)
  end
end
