require 'test_helper'

class MessagesControllerTest < ActionController::TestCase

  def setup
    @person = FixtureFactory::Person.create
    @other_person = FixtureFactory::Person.create
  end
  
  should "create new wall posts" do
    body = Faker::Lorem.sentence
    post :create, {:wall_id => @person, :message => {:body => body}}, {:logged_in_id => @other_person}
    assert_redirected_to person_path(@person, :hash => 'wall')
  end
   
  should "create new wall posts via ajax" do
    body = Faker::Lorem.sentence
    post :create, {:wall_id => @person, :message => {:body => body}, :format => 'js'}, {:logged_in_id => @other_person}
    assert_response :success
    assert_template '_wall'
  end

  should "not create a new wall post if the user cannot see the person's profile" do
    @person.update_attribute :visible, false
    body = Faker::Lorem.sentence
    post :create, {:wall_id => @person, :message => {:body => body}}, {:logged_in_id => @other_person}
    assert_response :missing
  end
  
  should "not create a new wall post if the person's wall is disabled" do
    @person.update_attribute :wall_enabled, false
    body = Faker::Lorem.sentence
    post :create, {:wall_id => @person, :message => {:body => body}}, {:logged_in_id => @other_person}
    assert_response :missing
  end
  
  should "delete a wall post" do
    @message = @person.wall_messages.create! :subject => 'Wall Post', :body => Faker::Lorem.sentence, :person => @other_person
    post :destroy, {:id => @message}, {:logged_in_id => @person}
    assert_response :redirect
  end
  
  should "delete a group message" do
    @group = Group.create! :name => 'Some Group', :category => 'test'
    @message = @group.messages.create! :subject => 'Just a Test', :body => Faker::Lorem.paragraph, :person => @person
    post :destroy, {:id => @message}, {:logged_in_id => @person}
    assert_response :redirect
  end
  
  should "not allow anyone but an admin or the owner to delete a wall post" do
    @message = @person.wall_messages.create! :subject => 'Wall Post', :body => Faker::Lorem.sentence, :person => @person
    post :destroy, {:id => @message}, {:logged_in_id => @other_person}
    assert_response :error
  end
  
  should "create new private messages" do
    body = Faker::Lorem.sentence
    post :create, {:person_id => @person, :message => {:subject => 'Hello There', :body => body}}, {:logged_in_id => @other_person}
    assert_response :success
    assert_select 'body', /message.+sent/
    
  end
  
  should "create new group messages"

end
