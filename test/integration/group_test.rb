class GroupTest < ActionController::IntegrationTest
  def test_search
    sign_in_as people(:tim)
    get '/groups'
    assert_select 'body', :html => /pending approval.*Morgan\sGroup/
    sign_in_as people(:jeremy)
    get '/groups/search?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /Morgan Group/
    sign_in_as people(:jeremy)
    get '/groups/search?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /no groups found/
    sign_in_as people(:tim)
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