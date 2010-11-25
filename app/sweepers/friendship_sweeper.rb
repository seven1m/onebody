class FriendshipSweeper < ActionController::Caching::Sweeper
  observe Friendship

  def expire_friends_list(record)
    ActionController::Base.cache_store.delete_matched(%r{people/(#{record.person_id}|#{record.friend_id})\?fragment=friends})
  end

  def after_save(record)
    expire_friends_list(record)
  end

  def after_destroy(record)
    expire_friends_list(record)
  end
end
