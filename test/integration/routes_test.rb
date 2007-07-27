require "#{File.dirname(__FILE__)}/../test_helper"

class RoutesTest < ActionController::IntegrationTest
  fixtures :people, :families, :groups

  def test_people_routes
    sign_in_as people(:jeremy)
    get '/people'
    assert_response :success
    assert_template 'people/view'
    get '/people/index'
    assert_response :success
    assert_template 'people/view'
    #get '/people/2' # removed this routing style, as it was causing problems
    #assert_response :success
    #assert_template 'people/view'
    get '/people/view/2'
    assert_response :success
    assert_template 'people/view'
    get '/people/edit'
    assert_response :success
    assert_template 'people/edit'
    get '/people/edit/2'
    assert_response :success
    assert_template 'people/edit'
  end
end
