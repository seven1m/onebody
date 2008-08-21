require File.dirname(__FILE__) + '/../test_helper'

class AccountsControllerTest < ActionController::TestCase
  
  def setup
    @person, @other_person = Person.forge, Person.forge
  end
  
  should "edit account" do
    password_was = @person.encrypted_password
    get :edit, {:person_id => @person.id}, {:logged_in_id => @person.id}
    assert_response :success
    post :update, {:person_id => @person.id, :person => {:email => 'foo@example.com'}, :password => 'password', :password_confirmation => 'password'}, {:logged_in_id => @person.id}
    assert_redirected_to person_path(@person)
    assert_equal 'foo@example.com', @person.reload.email
    assert @person.encrypted_password != password_was
  end
  
  should "not edit account unless user is admin" do
    get :edit, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
    post :update, {:person_id => @person.id, :person => {:email => 'foo@example.com'}, :password => 'password', :password_confirmation => 'password'}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
  end
  
  should "verify a code" do
    v = Verification.create!(:email => @person.email)
    get :verify_code, {:id => v.id, :code => v.code}
    assert_response :redirect
  end
  
end
