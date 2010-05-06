class FriendshipSweeper < ActionController::Caching::Sweeper
  observe Friendship, FriendshipRequest

  def after_save(record)
    if record.is_a? FriendshipRequest
      expire_fragment(%r{views/people/#{record.person_id}_})
      expire_fragment(%r{views/people/#{record.from_id}_})
    elsif record.is_a? Friendship
      expire_fragment(%r{views/people/#{record.person_id}_})
      expire_fragment(%r{views/people/#{record.friend_id}_})
    end
  end

  alias_method :after_destroy, :after_save

end
