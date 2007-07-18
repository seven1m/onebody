class FriendsController < ApplicationController
  before_filter :get_friendship, :only => ['remove']
  before_filter :get_request, :only => ['accept', 'decline']
  
  verify :method => :post, :only => ['add', 'accept', 'decline', 'remove']
  
  def view
    if params[:id]
      @person = Person.find(params[:id])
      @pending = []
    else
      @person = @logged_in
      @pending = @logged_in.pending_friendship_requests
    end
    @friendships = @person.friendships
  end
  
  def add
    @person = Person.find params[:id]
    if @person.friendship_waiting_on?(@logged_in) # already requested by other person
      @logged_in.friendships.create! :friend => @person
      @logged_in.friendship_requests.find_by_from_id(@person.id).destroy
      message = "#{@person.name} has been added as a friend."
    elsif @logged_in.can_request_friendship_with?(@person)
      FriendshipRequest.delete_all ['person_id = ? and from_id = ? and rejected = ?', @logged_in.id, @person.id, true] # clean up past rejections
      @person.friendship_requests.create!(:from => @logged_in)
      message = "A friend request has been sent to #{@person.name}."
    elsif @logged_in.friendship_waiting_on?(@person)
      message = "A friend request is already pending with #{@person.name}."
    elsif @logged_in.friendship_rejected_by?(@person) # there's really no way in the interface to get here, but oh well
      message = :turned_down
    else
      raise 'unknown state'
    end
    respond_to do |wants|
      wants.html do
        render message.is_a?(String) ? {:text => message, :layout => true} : {:action => message}
      end
      wants.js do
        render :update do |page|
          if message.is_a? String
            page.hide "add_friend_#{@person.id}"
            page.alert message
          elsif message.is_a? Symbol
            page.redirect_to :action => message
          end
        end
      end
    end
  end
  
  def accept
    if @request
      @logged_in.friendships.create!(:friend => @request.from)
      @request.destroy
    end
    redirect_to friends_url(:id => nil)
  end
  
  def decline
    @request.update_attribute(:rejected, true) if @request
    redirect_to friends_url(:id => nil)
  end
  
  def remove
    @friendship.destroy if @friendship
    redirect_to friends_url(:id => nil)
  end
  
  def reorder
    params[:friends].each_with_index do |id, index|
      if f = @logged_in.friendships.find_by_id(id)
        f.update_attribute :ordering, index
      end
    end
    render :nothing => true
  end
  
  private
    def get_friendship
      @friendship = @logged_in.friendships.find_by_friend_id(params[:id])
    end
    
    def get_request
      @request = @logged_in.friendship_requests.find_by_id(params[:id])
    end
end
