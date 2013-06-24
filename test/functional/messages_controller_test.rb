require_relative '../test_helper'

class MessagesControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = Person.forge, Person.forge
    @group = Group.create! :name => 'Some Group', :category => 'test'
    @group.memberships.create! :person => @person
  end

  should "delete a group message" do
    @message = @group.messages.create! :subject => 'Just a Test', :body => Faker::Lorem.paragraph, :person => @person
    post :destroy, {:id => @message.id}, {:logged_in_id => @person.id}
    assert_response :redirect
  end

  should "create new private messages" do
    ActionMailer::Base.deliveries = []
    get :new, {:to_person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :success
    body = Faker::Lorem.sentence
    post :create, {:message => {:to_person_id => @person.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_select 'body', /message.+sent/
    assert ActionMailer::Base.deliveries.any?
  end

  should "render preview of private message" do
    ActionMailer::Base.deliveries = []
    body = Faker::Lorem.sentence
    post :create, {:format => 'js', :preview => true, :message => {:to_person_id => @person.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template 'create'
    assert ActionMailer::Base.deliveries.empty?
  end

  should "create new group messages" do
    ActionMailer::Base.deliveries = []
    get :new, {:group_id => @group.id}, {:logged_in_id => @person.id}
    assert_response :success
    body = Faker::Lorem.sentence
    post :create, {:message => {:group_id => @group.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_redirected_to group_path(@group)
    assert_match /has been sent/, flash[:notice]
    assert ActionMailer::Base.deliveries.any?
  end

  should "render preview of group message" do
    ActionMailer::Base.deliveries = []
    body = Faker::Lorem.sentence
    post :create, {:format => 'js', :preview => true, :message => {:group_id => @group.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @person.id}
    assert_response :success
    assert_template 'create'
    assert ActionMailer::Base.deliveries.empty?
  end

  should "not allow someone to post to a group they don't belong to unless they're an admin" do
    get :new, {:group_id => @group.id}, {:logged_in_id => @other_person.id}
    assert_response :error
    body = Faker::Lorem.sentence
    post :create, {:message => {:group_id => @group.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @other_person.id}
    assert_response :error
  end

  should "create new group messages with an attachment" do
    ActionMailer::Base.deliveries = []
    get :new, {:group_id => @group.id}, {:logged_in_id => @person.id}
    assert_response :success
    body = Faker::Lorem.sentence
    post :create, {:files => [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)], :message => {:group_id => @group.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_redirected_to group_path(@group)
    assert_match /has been sent/, flash[:notice]
    assert ActionMailer::Base.deliveries.any?
    assert_equal 1, Message.last.attachments.count
  end

  should "create new private messages with an attachment" do
    ActionMailer::Base.deliveries = []
    get :new, {:to_person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :success
    body = Faker::Lorem.sentence
    post :create, {:files => [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)], :message => {:to_person_id => @person.id, :subject => 'Hello There', :body => body}}, {:logged_in_id => @person.id}
    assert_response :success
    assert_select 'body', /message.+sent/
    assert ActionMailer::Base.deliveries.any?
    assert_equal 1, Message.last.attachments.count
  end

  should "show a message" do
    @message = @group.messages.create!(:person => @person, :subject => 'test subject', :body => 'test body')
    get :show, {:id => @message.id}, {:logged_in_id => @person.id}
    assert_response :success
  end

  should "show a message with an attachment" do
    @message = Message.create_with_attachments(
      {:group => @group, :person => @person, :subject => 'test subject', :body => 'test body'},
      [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)]
    )
    @attachment = @message.attachments.first
    get :show, {:id => @message.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_select 'body', /attachment\.pdf/
  end

end
