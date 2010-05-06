require File.dirname(__FILE__) + '/../test_helper'

class FriendsControllerTest < ActionController::TestCase

  def setup
    @person, @friend, @other_person = Person.forge, Person.forge, Person.forge
    @friendship = @person.friendships.create(:friend => @friend)
  end

  should "list all friends" do
    # self
    get :index, {:person_id => @person.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 1, assigns(:friendships).length
    # friend
    get :index, {:person_id => @person.id}, {:logged_in_id => @friend.id}
    assert_response :success
    assert_equal 1, assigns(:friendships).length
    # someone else
    get :index, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_equal 1, assigns(:friendships).length
  end

  should "not show friends if user cannot see the person" do
    @person.update_attribute(:visible, false)
    get :index, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end

  should "not show friends that the user cannot see" do
    @friend.update_attribute(:visible, false)
    get :index, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_equal 0, assigns(:friendships).length
  end

  should "list pending friendships" do
    @pending = @person.friendship_requests.create(:from => @other_person)
    get :index, {:person_id => @person.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 1, assigns(:pending).length
  end

  should "not list pending friendships for anyone but the user" do
    @pending = @person.friendship_requests.create(:from => @other_person)
    get :index, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_equal 0, assigns(:pending).length
  end

  should "create a friendship request" do
    req_count = FriendshipRequest.count
    post :create, {:person_id => @person.id, :friend_id => @other_person.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal req_count+1, FriendshipRequest.count
  end

  should "accept a friendship request" do
    friendship_count = Friendship.count
    @req = @person.friendship_requests.create!(:from => @other_person)
    post :update, {:person_id => @person.id, :id => @req.id, :accept => true}, {:logged_in_id => @person.id}
    assert_redirected_to person_friends_path(@person)
    assert_raise(ActiveRecord::RecordNotFound) do
      @req.reload
    end
    assert_equal friendship_count+2, Friendship.count # friendships are mirrored (2 records per friendship)
  end

  should "reject a friendship request" do
    friendship_count = Friendship.count
    @req = @person.friendship_requests.create!(:from => @other_person)
    post :update, {:person_id => @person.id, :id => @req.id, :reject => true}, {:logged_in_id => @person.id}
    assert_redirected_to person_friends_path(@person)
    assert @req.reload.rejected
    assert_equal friendship_count, Friendship.count
  end

  should "delete a friendship" do
    friendship_count = Friendship.count
    post :destroy, {:person_id => @person.id, :id => @friendship.friend.id}, {:logged_in_id => @person.id}
    assert_redirected_to person_friends_path(@person)
    assert_raise(ActiveRecord::RecordNotFound) do
      @friendship.reload
    end
    assert_equal friendship_count-2, Friendship.count # friendships are mirrored (2 records per friendship)
  end

  should "reorder friends" do
    @other_friendship = @person.friendships.create(:friend => @other_person)
    post :reorder, {:person_id => @person.id, :friends => [@friendship.id, @other_friendship.id]}, {:logged_in_id => @person.id}
    assert_equal 0, @friendship.reload.ordering
    assert_equal 1, @other_friendship.reload.ordering
    post :reorder, {:person_id => @person.id, :friends => [@other_friendship.id, @friendship.id]}, {:logged_in_id => @person.id}
    assert_equal 0, @other_friendship.reload.ordering
    assert_equal 1, @friendship.reload.ordering
  end

end
