require "#{File.dirname(__FILE__)}/../test_helper"

class PrivacyTest < ActionController::IntegrationTest
  fixtures :people, :families
  
  def sign_in_as(person)
    post '/account/sign_in', :email => person.email, :password => 'secret'
    assert_redirected_to :controller => 'people', :action => 'index'
    follow_redirect!
    assert_template 'people/view'
  end

  def test_help_for_parents_with_hidden_children
    sign_in_as people(:tim)
    get '/people/index'
    assert_response :success
    assert_template 'people/view'
    assert_select '#sidebar', /Why can't I see my children here\?/
    assert_select '#sidebar a[href=?]', /\/help\/safeguarding_children/
    assert_select '#sidebar tr.family-member', 2 # not 3
  end
  
  def test_children_hidden
    sign_in_as people(:peter)
    get "/people/view/#{people(:tim).id}"
    assert_response :success
    assert_template 'people/view'
    assert_select '#sidebar tr.family-member', 2 # not 3
  end
end
