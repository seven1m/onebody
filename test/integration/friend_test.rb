require "#{File.dirname(__FILE__)}/../test_helper"

class FriendTest < ActionController::IntegrationTest
  fixtures :people, :families, :friendships

  def setup
    Setting.set(1, 'Features', 'Friends', true)
  end

  def test_proper_links
    sign_in_as people(:jeremy)

    view_profile people(:tim)
    assert_select '#subnav', :html => /Remove from Friends/
    get '/directory/browse'
    assert_select '#add_friend_' + people(:tim).id.to_s, :count => 0

    view_profile people(:jane)
    assert_select '#subnav', :html => /Add to Friends/
    get '/search', :browse => true
    assert_select '#add_friend_' + people(:jane).id.to_s

    post "/people/#{people(:jeremy).id}/friends?friend_id=#{people(:jane).id}"
    assert_response :success
    assert_select 'body', :html => /friend request has been sent/

    get '/search', :browse => true
    assert_select '#add_friend_' + people(:jane).id.to_s, :count => 0
    view_profile people(:jane)
    assert_select '#subnav', :html => /friend request pending/

    sign_in_as people(:jane)
    assert_select 'body', :html => /pending friend requests/
    f = people(:jane).friendship_requests.find_by_from_id(people(:jeremy).id)

    put "/people/#{people(:jane).id}/friends/#{f.id}?accept=true"
    assert_response :redirect
    view_profile people(:jeremy)
    assert_select '#subnav', :html => /Remove from Friends/

    get '/search', :browse => true
    assert_select '#add_friend_' + people(:jeremy).id.to_s, :count => 0
  end
end
