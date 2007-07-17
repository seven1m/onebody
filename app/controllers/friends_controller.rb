class FriendsController < ApplicationController
  def add
    if request.post?
      
    end
  end
  
  def remove
    if request.post?
      @logged_in.friendships.find_by_friend_id(params[:id]).destroy rescue nil
    end
    redirect_to logged_in_url
  end
end
