require "#{File.dirname(__FILE__)}/../test_helper"

class GroupsTest < ActionController::IntegrationTest
  def test_search
    sign_in_as people(:tim)
    get '/groups'
    assert_select 'body', :html => /pending approval.*Morgan\sGroup/m
    sign_in_as people(:jeremy)
    get '/groups?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /College Group/
    assert_select 'body', :html => /Morgan Group/, :count => 0
    sign_in_as people(:tim)
    get '/groups?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /College Group/
    assert_select 'body', :html => /Morgan Group/
    get 'groups/1'
    assert_select 'body', :html => /Approve Group/
    put '/groups/1?group[approved]=true'
    assert_redirected_to group_path(:id => 1)
    assert_select 'body', :html => /Approve Group/, :count => 0
    get '/groups?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /Morgan\sGroup/
  end

  def test_disable_email
    # with code
    put "/groups/#{groups(:college).id}/memberships/#{people(:jeremy).id}?code=#{people(:jeremy).feed_code}&email=off"
    assert !groups(:college).get_options_for(people(:jeremy)).get_email
    put "/groups/#{groups(:college).id}/memberships/#{people(:jeremy).id}?code=#{people(:jeremy).feed_code}&email=on"
    assert groups(:college).get_options_for(people(:jeremy)).get_email
    # signed in
    sign_in_as people(:jeremy)
    put "/groups/#{groups(:college).id}/memberships/#{people(:jeremy).id}?email=off"
    assert !groups(:college).get_options_for(people(:jeremy)).get_email
    put "/groups/#{groups(:college).id}/memberships/#{people(:jeremy).id}?email=on"
    assert groups(:college).get_options_for(people(:jeremy)).get_email
    # GET request
    get "/groups/#{groups(:college).id}/memberships/#{people(:jeremy).id}?code=#{people(:jeremy).feed_code}&email=off"
    assert !groups(:college).get_options_for(people(:jeremy)).get_email
    get "/groups/#{groups(:college).id}/memberships/#{people(:jeremy).id}?code=#{people(:jeremy).feed_code}&email=on"
    assert groups(:college).get_options_for(people(:jeremy)).get_email
  end
end
