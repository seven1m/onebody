require "#{File.dirname(__FILE__)}/../test_helper"

class FriendTest < ActionController::IntegrationTest
  def setup
    Setting.set(1, 'Features', 'Friends', true)
    @user = FactoryGirl.create(:person)
    @friend = FactoryGirl.create(:person)
    @stranger = FactoryGirl.create(:person)
    Friendship.create!(person: @user, friend: @friend)
  end

  def test_proper_links
    sign_in_as @user

    view_profile @friend
    assert_select 'body', html: /Remove from Friends/
    assert_select '#add_friend_' + @friend.id.to_s, count: 0

    view_profile @stranger
    assert_select 'body', html: /Add to Friends/
    assert_select '#add_friend_' + @stranger.id.to_s

    post "/people/#{@user.id}/friends?friend_id=#{@stranger.id}"
    assert_response :success
    assert_select 'body', html: /friend request has been sent/

    view_profile @stranger
    assert_select '#add_friend_' + @stranger.id.to_s, count: 0
    assert_select 'body', html: /friend request pending/

    sign_in_as @stranger
    assert_select 'body', html: /pending friend requests/
    f = @stranger.friendship_requests.find_by_from_id(@user.id)

    put "/people/#{@stranger.id}/friends/#{f.id}?accept=true"
    assert_response :redirect
    view_profile @user
    assert_select 'body', html: /Remove from Friends/
    assert_select '#add_friend_' + @user.id.to_s, count: 0
  end
end
