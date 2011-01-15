require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < ActiveSupport::TestCase
  include MessagesHelper

  def setup
    @person, @second_person, @third_person = Person.forge, Person.forge, Person.forge
    @admin_person = Person.forge(:admin_id => Admin.create(:manage_groups => true).id)
    @group = Group.create! :name => 'Some Group', :category => 'test'
    @group.memberships.create! :person => @person
  end

  should "create a new message with attachments" do
    files = [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)]
    @message = Message.create_with_attachments({:to => @person, :person => @second_person, :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph}, files)
    assert_equal 1, @message.attachments.count
  end

  should "preview a message" do
    subject, body = Faker::Lorem.sentence, Faker::Lorem.paragraph
    @preview = Message.preview(:to => @person, :person => @second_person, :subject => subject, :body => body)
    assert_equal subject, @preview.subject
    @body = get_email_body(@preview)
    assert @body.to_s.index(body)
    assert_match(/Hit "Reply" to send a message/, @body.to_s)
    assert_match(/http:\/\/.+\/privacy/, @body.to_s)
  end

  should "know who can see the message" do
    # group message
    @message = Message.create(:group => @group, :person => @person, :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph)
    assert @person.can_see?(@message)
    assert !@second_person.can_see?(@message)
    assert @admin_person.can_see?(@message)
    # group message in private group
    @group.update_attributes! :private => true
    assert !@third_person.can_see?(@message)
    # private message
    @message = Message.create(:to => @second_person, :person => @person, :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph)
    assert @person.can_see?(@message)
    assert @second_person.can_see?(@message)
    assert !@third_person.can_see?(@message)
  end

  should 'allow a message without body if it has an html body' do
    @message = Message.create(:subject => 'foo', :html_body => 'bar', :person => @person, :group => @group)
    assert @message.valid?
  end

  should 'be invalid if no body or html body' do
    @message = Message.create(:subject => 'foo', :person => @person, :group => @group)
    assert !@message.valid?
    assert @message.errors[:body].any?
  end
end
