require File.dirname(__FILE__) + '/../test_helper'

class MessagesControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = Person.forge, Person.forge
    @group = Group.create! :name => 'Some Group', :category => 'test'
    @group.memberships.create! :person => @person
  end
  
  should "create new wall posts" do
    ActionMailer::Base.deliveries = []
    body = Faker::Lorem.sentence
    post :create, {:message => {:wall_id => @person.id, :body => body}}, {:logged_in_id => @other_person}
    assert_redirected_to person_path(@person) + '#wall'
    assert ActionMailer::Base.deliveries.any?
  end
   
  should "create new wall posts via ajax" do
    ActionMailer::Base.deliveries = []
    body = Faker::Lorem.sentence
    post :create, {:message => {:wall_id => @person.id, :body => body}, :format => 'js'}, {:logged_in_id => @other_person}
    assert_response :success
    assert_template '_wall'
    assert ActionMailer::Base.deliveries.any?
  end

  should "not create a new wall post if the user cannot see the person's profile" do
    @person.update_attribute :visible, false
    body = Faker::Lorem.sentence
    post :create, {:message => {:wall_id => @person.id, :body => body}}, {:logged_in_id => @other_person}
    assert_response :missing
  end
  
  should "not create a new wall post if the person's wall is disabled" do
    @person.update_attribute :wall_enabled, false
    body = Faker::Lorem.sentence
    post :create, {:message => {:wall_id => @person.id, :body => body}}, {:logged_in_id => @other_person}
    assert_response :missing
  end
  
  should "delete a wall post" do
    @message = @person.wall_messages.create! :subject => 'Wall Post', :body => Faker::Lorem.sentence, :person => @other_person
    post :destroy, {:id => @message.id}, {:logged_in_id => @person}
    assert_response :redirect
  end
  
  should "delete a group message" do
    @message = @group.messages.create! :subject => 'Just a Test', :body => Faker::Lorem.paragraph, :person => @person
    post :destroy, {:id => @message.id}, {:logged_in_id => @person}
    assert_response :redirect
  end
  
  should "not allow anyone but an admin or the owner to delete a wall post" do
    @message = @person.wall_messages.create! :subject => 'Wall Post', :body => Faker::Lorem.sentence, :person => @person
    post :destroy, {:id => @message.id}, {:logged_in_id => @other_person}
    assert_response :error
  end
  
  should "create new private messages" do
    ActionMailer::Base.deliveries = []
    get :new, {:to_person_id => @person.id}, {:logged_in_id => @other_person}
    assert_response :success
    body = Faker::Lorem.sentence
    post :create, {:message => {:to_person_id => @person.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @other_person}
    assert_response :success
    assert_select 'body', /message.+sent/
    assert ActionMailer::Base.deliveries.any?
  end
  
  should "render preview of private message" do
    ActionMailer::Base.deliveries = []
    body = Faker::Lorem.sentence
    post :create, {:format => 'js', :preview => true, :message => {:to_person_id => @person.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @other_person}
    assert_response :success
    assert_template 'create'
    assert ActionMailer::Base.deliveries.empty?
  end
  
  should "create new group messages" do
    ActionMailer::Base.deliveries = []
    get :new, {:group_id => @group.id}, {:logged_in_id => @person}
    assert_response :success
    body = Faker::Lorem.sentence
    post :create, {:message => {:group_id => @group.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @person}
    assert_response :redirect
    assert_redirected_to group_path(@group)
    assert_match /has been sent/, flash[:notice]
    assert ActionMailer::Base.deliveries.any?
  end
  
  should "render preview of group message" do
    ActionMailer::Base.deliveries = []
    body = Faker::Lorem.sentence
    post :create, {:format => 'js', :preview => true, :message => {:group_id => @group.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @person}
    assert_response :success
    assert_template 'create'
    assert ActionMailer::Base.deliveries.empty?
  end
  
  should "not allow someone to post to a group they don't belong to unless they're an admin" do
    get :new, {:group_id => @group.id}, {:logged_in_id => @other_person}
    assert_response :error
    body = Faker::Lorem.sentence
    post :create, {:message => {:group_id => @group.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @other_person}
    assert_response :error
  end
  
  should "create new group messages with an attachment" do
    ActionMailer::Base.deliveries = []
    get :new, {:group_id => @group.id}, {:logged_in_id => @person}
    assert_response :success
    body = Faker::Lorem.sentence
    post :create, {:file => fixture_file_upload('files/attachment.pdf'), :message => {:group_id => @group.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @person}
    assert_response :redirect
    assert_redirected_to group_path(@group)
    assert_match /has been sent/, flash[:notice]
    assert ActionMailer::Base.deliveries.any?
  end
  
  should "create new private messages with an attachment" do
    ActionMailer::Base.deliveries = []
    get :new, {:to_person_id => @person.id}, {:logged_in_id => @other_person}
    assert_response :success
    body = Faker::Lorem.sentence
    post :create, {:file => fixture_file_upload('files/attachment.pdf'), :message => {:to_person_id => @person.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @person}
    assert_response :success
    assert_select 'body', /message.+sent/
    assert ActionMailer::Base.deliveries.any?
  end
  
  should "show a message" do
    @message = @group.messages.create!(:person => @person, :subject => 'test subject', :body => 'test body')
    get :show, {:id => @message.id}, {:logged_in_id => @person}
    assert_response :success
  end
  
  should "show a message with an attachment" do
    @message = Message.create_with_attachments(
      {:group => @group, :person => @person, :subject => 'test subject', :body => 'test body'},
      [fixture_file_upload('files/attachment.pdf')]
    )
    @attachment = @message.attachments.first
    get :show, {:id => @message.id}, {:logged_in_id => @person}
    assert_response :success
    assert_select 'body', /attachment\.pdf/
  end

end
