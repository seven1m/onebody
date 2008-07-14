require File.dirname(__FILE__) + '/../test_helper'

class AttachmentsControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = Person.forge, Person.forge
    @group = Group.create! :name => 'Some Group', :category => 'test'
    @group.memberships.create! :person => @person
    @message = Message.create_with_attachments(
      {:group => @group, :person => @person, :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph},
      [fixture_file_upload('files/attachment.pdf')]
    )
    @attachment = @message.attachments.first
  end
  
  should "show an attachment" do
    get :show, {:message_id => @message.id, :id => @attachment.id}, {:logged_in_id => @person}
    assert_response :success
  end
  
  should "not show an attachment unless the person can see what it is attached to" do
    get :show, {:message_id => @message.id, :id => @attachment.id}, {:logged_in_id => @other_person}
    assert_response :missing
  end

end
