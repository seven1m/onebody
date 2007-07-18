require "#{File.dirname(__FILE__)}/../test_helper"

class FriendTest < ActionController::IntegrationTest
  fixtures :people, :families, :friendships, :friendship_requests

  def sign_in_as(person, password='secret')
    post '/account/sign_in', :email => person.email, :password => password
    assert_redirected_to :controller => 'people', :action => 'index'
    follow_redirect!
    assert_template 'people/view'
    assert_select 'h1', Regexp.new(person.name)
  end
  
  def view_profile(person)
    get "/people/view/#{person.id}"
    assert_response :success
    assert_template 'people/view'
  end

  def test_proper_links
    sign_in_as people(:jeremy)
    view_profile people(:jeanette)
    assert_select '', :html => 'Add to Friends', :count => 1
    view_profile people(:tim)
    assert_select '', :html => 'Remove from Friends', :count => 1
  end
end
