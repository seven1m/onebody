class FriendsController < ApplicationController
  before_filter :get_friendship, :except => ['index', 'reorder']
  
  def index
    @pending = @logged_in.all_friendships.find_all_by_pending(true)
    @friendships = @logged_in.friendships.find(:all, :order => 'ordering, created_at')
  end
  
  def add
    if request.post?
      if @friendship
        if @friendship.pending
          if @friendship.initiated_by == @logged_in
            render :text => 'A friend request is already pending with #{@person.name}.', :layout => true
          else
            @friendship.update_attribute :pending, false
            flash[:notice] = "#{@person.name} has been added as a friend."
            redirect_to logged_in_url
          end
        elsif @friendship.rejected
          if @friendship.rejected_by == @logged_in
            @friendship.destroy
            @logged_in.friendships.create(:friend_id => params[:id])
            render :text => "A friend request has been sent to #{@person.name}.", :layout => true
          else
            render :action => 'turned_down'
          end
        end
      else
        if @person.friendship_requests
          @logged_in.friendships.create(:friend_id => params[:id])
          render :text => "A friend request has been sent to #{@person.name}.", :layout => true
        else
          render :text => 'This person does not accept friend requests.', :layout => true
        end
      end
    end
  end
  
  def accept
    if request.post? and @friendship and @friendship.pending and @friendship.initated_by == @person
      @friendship.update_attribute :pending, false
    end
    redirect_to logged_in_url
  end
  
  def decline
    if request.post? and @friendship and @friendship.pending and @friendship.initated_by == @person
      @friendship.update_attributes :rejected => true, :rejected_by => @logged_in, :pending => false
    end
    redirect_to logged_in_url
  end
  
  def remove
    @friendship.destroy if request.post? and @friendship
    redirect_to logged_in_url
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
      @person = Person.find(params[:id])
      @friendship = @logged_in.all_friendships.find_by_friend_id(params[:id])
    end
end
