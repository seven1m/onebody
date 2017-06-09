class FriendsController < ApplicationController
  before_filter :person_must_be_user, except: %w(index)

  def index
    @person = Person.find(params[:person_id])
    if @logged_in.can_read?(@person)
      @pending = me? ? @person.pending_friendship_requests : []
      @friendships = @person.friendships.to_a.select { |f| f.friend && @logged_in.can_read?(f.friend) }
    else
      render text: t('people.not_found'), layout: true, status: 404
    end
  end

  # friend_id = Person (other person)
  def create
    @person = Person.find(params[:person_id])
    @other_person = Person.find(params[:friend_id])
    @message = @person.request_friendship_with(@other_person)
    respond_to do |wants|
      wants.html
      wants.js
    end
  end

  # id = FriendshipRequest
  def update
    @person = Person.find(params[:person_id])
    @friendship_request = @person.friendship_requests.find(params[:id])
    if params[:accept]
      @friendship_request.accept
      flash[:notice] = t('people.friendship_accepted')
      redirect_to person_friends_path(@person)
    elsif params[:reject]
      @friendship_request.reject
      flash[:notice] = t('people.friendship_rejected')
      redirect_to person_friends_path(@person)
    else
      render text: t('people.friendship_must_specify'), layout: true, status: 500
    end
  end

  # id = Person (friend)
  def destroy
    @person = Person.find(params[:person_id])
    if @friendship = @person.friendships.where(friend_id: params[:id]).first
      @friendship.destroy
      redirect_to person_friends_path(@person)
    else
      render text: t('people.friend_not_found'), layout: true, status: 404
    end
  end

  def reorder
    @person = Person.find(params[:person_id])
    params[:friends].each_with_index do |id, index|
      if f = @person.friendships.where(id: id).first
        f.update_attribute :ordering, index
      end
    end
    render nothing: true
  end

  private

  def person_must_be_user
    unless @logged_in.id == params[:person_id].to_i
      render text: t('people.friendship_manage'), layout: true, status: 401
      false
    end
  end
end
