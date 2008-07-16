require File.dirname(__FILE__) + '/../test_helper'

class SessionsControllerTest < ActionController::TestCase
  
  def setup
    Setting.set_global('Features', 'SSL', true)
    @person = Person.forge(:encrypted_password => '5ebe2294ecd0e0f08eab7690d2a6ee69')
  end
  
  should "redirect show action to new action" do
    get :show
    assert_redirected_to new_session_path
  end
  
  should "present a login form" do
    get :new
    assert_response :success
    assert_template 'new'
  end
  
  should "sign in a user" do
    post :create, {:email => @person.email, :password => 'secret'}
    assert_nil flash[:warning]
    assert_redirected_to person_path(@person)
    assert_equal @person.id, session[:logged_in_id]
  end
  
  should "sign out a user" do
    post :destroy
    assert_redirected_to new_session_path
    assert_nil session[:logged_in_id]
  end
  
  should "redirect to original location after sign in" do
    post :create, {:email => @person.email, :password => 'secret', :from => "/groups"}
    assert_redirected_to groups_path
  end
  
end
