require File.dirname(__FILE__) + '/../test_helper'

class WallsControllerTest < ActionController::TestCase
  
  def setup
    @person, @other_person = Person.forge, Person.forge
    15.times { @person.wall_messages.create! :subject => 'Wall Post', :body => Faker::Lorem.sentence, :person => @other_person }
    12.times { @other_person.wall_messages.create! :subject => 'Wall Post', :body => Faker::Lorem.sentence, :person => @person }
  end
    
  should "show all messages from one person's wall when rendered as html" do
    get :show, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template 'show'
    assert assigns(:person)
    assert assigns(:messages)
    assert_equal @person.wall_messages.count, assigns(:messages).length
  end

  should "show 10 messages from one person's wall when rendered for ajax" do
    get :show, {:person_id => @person.id, :format => 'js'}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template '_wall'
    assert assigns(:person)
    assert assigns(:messages)
    assert_equal 10, assigns(:messages).length
  end

  should "not show a peron's wall if the user cannot see the profile" do
    @person.update_attribute :visible_to_everyone, false
    get :show, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "not show a person's wall if they have it disabled" do
    @person.update_attribute :wall_enabled, false
    get :show, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "show the interaction of two people (wall-to-wall)" do
    get :with, {:person_id => @person.id, :id => @other_person.id}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template 'with'
    assert assigns(:person1)
    assert assigns(:person2)
    assert assigns(:messages)
    assert_equal (@person.wall_messages.count + @other_person.wall_messages.count), assigns(:messages).length
  end

  should "not show the interaction of two people (wall-to-wall) if any one of the people cannot be seen by the current user" do
    @person.update_attribute :visible_to_everyone, false
    get :with, {:person_id => @person.id, :id => @other_person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "not show the interaction of two people (wall-to-wall) if any of the people have their wall disabled" do
    @person.update_attribute :wall_enabled, false
    get :with, {:person_id => @person.id, :id => @other_person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "not show 'with' unless id is specified" do
    assert_raise(ActiveRecord::RecordNotFound) do
      get :with, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    end
  end

end
