require "#{File.dirname(__FILE__)}/../test_helper"

class GroupTest < ActionController::IntegrationTest
  fixtures :people, :groups
  
  def test_search
    sign_in_as people(:tim)
    get '/groups'
    assert_select 'body', :hmlt => /pending approval.*Morgan\sGroup/
    get '/groups/search?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /no groups found/
    get 'groups/view/1'
    assert_select 'body', :html => /Approve Group/
    post '/groups/approve/1'
    assert_redirected_to group_path(:id => 1)
    assert_select 'body', :html => /Approve Group/, :count => 0
    get '/groups/search?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /Morgan\sGroup/
  end
end
