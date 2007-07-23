require "#{File.dirname(__FILE__)}/../test_helper"

class FriendTest < ActionController::IntegrationTest
  fixtures :people, :families, :friendships, :friendship_requests
  
  def setup
    SETTINGS['features']['friends'] = true
  end

  def view_profile(person)
    get "/people/view/#{person.id}"
    assert_response :success
    assert_template 'people/view'
    assert_select 'h1', Regexp.new(person.name)
  end
  
  def request_friendship(person)
    post "/friends/add/#{person.id}"
    assert_response :success
  end

  def test_proper_links
    sign_in_as people(:jeremy)
    view_profile people(:tim)
    assert_select '#subnav', :html => /Remove from Friends/
    get '/people/browse'
    assert_select '#add_friend_' + people(:tim).id.to_s, :count => 0
    view_profile people(:jeanette)
    assert_select '#subnav', :html => /Add to Friends/
    get '/people/browse'
    assert_select '#add_friend_' + people(:jeanette).id.to_s
    request_friendship people(:jeanette)
    assert_select 'body', :html => /friend request has been sent/
    get '/people/browse'
    assert_select '#add_friend_' + people(:jeanette).id.to_s, :count => 0
    view_profile people(:jeanette)
    assert_select '#subnav', :html => /friend request pending/
    sign_in_as people(:jeanette)
    assert_select '.highlight', :html => /pending friend requests/
    f = people(:jeanette).friendship_requests.find_by_from_id(people(:jeremy).id)
    post "/friends/accept/#{f.id}"
    view_profile people(:jeremy)
    assert_select '#subnav', :html => /Remove from Friends/
    get '/people/browse'
    assert_select '#add_friend_' + people(:jeremy).id.to_s, :count => 0
  end
end
