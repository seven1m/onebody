require_relative '../spec_helper'

describe Message do
  include MessagesHelper

  before do
    @person, @second_person, @third_person = FactoryGirl.create_list(:person, 3)
    @admin_person = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    @group = Group.create! name: 'Some Group', category: 'test'
    @group.memberships.create! person: @person
  end

  it "should create a new message with attachments" do
    files = [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true)]
    @message = Message.create_with_attachments({to: @person, person: @second_person, subject: 'subject', body: 'body'}, files)
    expect(@message.attachments.count).to eq(1)
  end

  it "should preview a message" do
    @preview = Message.preview(to: @person, person: @second_person, subject: 'subject', body: 'body')
    expect(@preview.subject).to eq("subject")
    @body = get_email_body(@preview)
    expect(@body.to_s.index('body')).to be
    expect(@body.to_s).to match(/Hit "Reply" to send a message/)
    expect(@body.to_s).to match(/http:\/\/.+\/privacy/)
  end

  it "should know who can see the message" do
    # group message
    @message = Message.create(group: @group, person: @person, subject: 'subject', body: 'body')
    expect(@person.can_see?(@message)).to be
    expect(@second_person.can_see?(@message)).not_to be
    expect(@admin_person.can_see?(@message)).to be
    # group message in private group
    @group.update_attributes! private: true
    expect(@third_person.can_see?(@message)).not_to be
    # private message
    @message = Message.create(to: @second_person, person: @person, subject: 'subject', body: 'body')
    expect(@person.can_see?(@message)).to be
    expect(@second_person.can_see?(@message)).to be
    expect(@third_person.can_see?(@message)).not_to be
  end

  it 'should allow a message without body if it has an html body' do
    @message = Message.create(subject: 'foo', html_body: 'bar', person: @person, group: @group)
    expect(@message).to be_valid
  end

  it 'should be invalid if no body or html body' do
    @message = Message.create(subject: 'foo', person: @person, group: @group)
    expect(@message).to_not be_valid
    expect(@message.errors[:body]).to be_any
  end

  it 'should not allow two identical messages to be saved' do
    details = {subject: 'foo', body: 'foo', person: @person, group: @group}
    @message = Message.create!(details)
    @message2 = Message.new(details)
    expect(@message2).to_not be_valid
  end
end
