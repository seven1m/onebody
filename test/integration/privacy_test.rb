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
    assert_select '#sidebar tr.family-member', 2 # not 3 (should not see child)
  end
  
  def test_children_hidden
    sign_in_as people(:peter)
    get "/people/view/#{people(:tim).id}" # view Tim's profile
    assert_response :success
    assert_template 'people/view'
    assert_select '#sidebar tr.family-member', 2 # not 3 (should not see child)
    get "/people/view/#{people(:mac).id}" # view Mac's profile (child)
    assert_response :missing
    get "/people/search", :name => 'Mac'
    assert_template 'people/search'
    assert_select 'body', /Your search didn't match any people\./
    assert_equal '???', Person.find_by_first_name('Mac').name
    sign_in_as people(:tim)
    assert_equal 'Mac Morgan', Person.find_by_first_name('Mac').name
  end
end
