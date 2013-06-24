require "#{File.dirname(__FILE__)}/../test_helper"

class FriendTest < ActionController::IntegrationTest
  fixtures :people, :families, :friendships

  def setup
    Setting.set(1, 'Features', 'Friends', true)
  end

  def test_proper_links
    sign_in_as people(:jeremy)

    view_profile people(:tim)
    assert_select 'body', html: /Remove from Friends/
    assert_select '#add_friend_' + people(:tim).id.to_s, count: 0

    view_profile people(:jennie)
    assert_select 'body', html: /Add to Friends/
    assert_select '#add_friend_' + people(:jennie).id.to_s

    post "/people/#{people(:jeremy).id}/friends?friend_id=#{people(:jennie).id}"
    assert_response :success
    assert_select 'body', html: /friend request has been sent/

    view_profile people(:jennie)
    assert_select '#add_friend_' + people(:jennie).id.to_s, count: 0
    assert_select 'body', html: /friend request pending/

    sign_in_as people(:jennie), 'password'
    assert_select 'body', html: /pending friend requests/
    f = people(:jennie).friendship_requests.find_by_from_id(people(:jeremy).id)

    put "/people/#{people(:jennie).id}/friends/#{f.id}?accept=true"
    assert_response :redirect
    view_profile people(:jeremy)
    assert_select 'body', html: /Remove from Friends/
    assert_select '#add_friend_' + people(:jeremy).id.to_s, count: 0
  end
end
