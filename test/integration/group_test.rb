class GroupTest < ActionController::IntegrationTest
  def test_search
    sign_in_as people(:tim)
    get '/groups'
    assert_select 'body', :html => /pending approval.*Morgan\sGroup/
    sign_in_as people(:jeremy)
    get '/groups/search?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /College Group/
    assert_select 'body', :html => /Morgan Group/, :count => 0
    sign_in_as people(:tim)
    get '/groups/search?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /College Group/
    assert_select 'body', :html => /Morgan Group/
    get 'groups/view/1'
    assert_select 'body', :html => /Approve Group/
    post '/groups/approve/1'
    assert_redirected_to group_path(:id => 1)
    assert_select 'body', :html => /Approve Group/, :count => 0
    get '/groups/search?category=Small+Groups'
    assert_response :success
    assert_select 'body', :html => /Morgan\sGroup/
  end
  
  def test_disable_email
    sign_in_as people(:jeremy)
    assert groups(:college).get_options_for(people(:jeremy), true).get_email
    post "/groups/toggle_email/#{groups(:college).id}?person_id=#{people(:jeremy).id}"
    assert_redirected_to group_url(:id => groups(:college))
    assert !groups(:college).get_options_for(people(:jeremy)).get_email
    post "/groups/toggle_email/#{groups(:college).id}?person_id=#{people(:jeremy).id}"
    assert_redirected_to group_url(:id => groups(:college))
    assert groups(:college).get_options_for(people(:jeremy)).get_email
  end
end