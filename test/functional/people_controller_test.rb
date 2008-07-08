require File.dirname(__FILE__) + '/../test_helper'

class PeopleControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = Person.forge, Person.forge
    @limited_person = Person.forge(:full_access => false)
  end
  
  should "redirect the index action to the currently logged in person" do
    get :index, nil, {:logged_in_id => @person}
    assert_redirected_to :action => 'show', :id => @person.id
  end

  should "show a person" do
    get :show, {:id => @person}, {:logged_in_id => @person} # myself
    assert_response :success
    assert_template 'show'
    get :show, {:id => @person}, {:logged_in_id => @other_person} # someone else
    assert_response :success
    assert_template 'show'
  end
  
  should "show a limited view of a person" do
    get :show, {:id => @person}, {:logged_in_id => @limited_person}
    assert_response :success
    assert_template 'show_limited'
  end
  
  should "show a simple view" do
    get :show, {:id => @person, :simple => true}, {:logged_in_id => @other_person}
    assert_response :success
    assert_template 'show_simple'
  end
  
  should "show a simple photo view" do
    get :show, {:id => @person, :simple => true, :photo => true}, {:logged_in_id => @other_person}
    assert_response :success
    assert_template 'show_simple_photo'
  end
  
  should "not show a simple view to limited users" do
    get :show, {:id => @person, :simple => true}, {:logged_in_id => @limited_person}
    assert_response :missing
  end
  
  should "not show a simple photo view to limited users" do
    get :show, {:id => @person, :simple => true, :photo => true}, {:logged_in_id => @limited_person}
    assert_response :missing
  end
  
  should "not show a person if they are invisible to the logged in user" do
    @person.update_attribute :visible, false
    get :show, {:id => @person}, {:logged_in_id => @other_person}
    assert_response :missing
  end

end
