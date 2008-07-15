class FriendshipSweeper < ActionController::Caching::Sweeper
  observe Friendship, FriendshipRequest

  def after_save(record)
    if record.is_a? FriendshipRequest
      expire_action(:controller => 'people', :action => 'show', :id => record.person_id)
      expire_action(:controller => 'people', :action => 'show', :id => record.from_id)
    elsif record.is_a? Friendship
      expire_action(:controller => 'people', :action => 'show', :id => record.person_id)
      expire_action(:controller => 'people', :action => 'show', :id => record.friend_id)
    end
  end
  
  alias_method :after_destroy, :after_save
  
end
