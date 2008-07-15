class FriendshipSweeper < ActionController::Caching::Sweeper
  observe Friendship, FriendshipRequest

  def after_save(record)
    expire_action(:controller => 'people', :action => 'show', :id => record.person.id)
    expire_action(:controller => 'people', :action => 'show', :id => record.friend.id)
  end
  
  alias_method :after_destroy, :after_save
  
end
