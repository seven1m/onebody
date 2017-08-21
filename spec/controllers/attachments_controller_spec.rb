require_relative '../rails_helper'

describe AttachmentsController, type: :controller do
  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group = Group.create! name: 'Some Group', category: 'test', private: true
    @group.memberships.create! person: @person
    @message = Message.create_with_attachments(
      { group: @group, person: @person, subject: 'subject', body: 'body' },
      [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true)]
    )
    @attachment = @message.attachments.first
  end

  it 'should show an attachment' do
    get :show,
        params: { message_id: @message.id, id: @attachment.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
  end

  it 'should not show an attachment unless the person can see what it is attached to' do
    get :show,
        params: { message_id: @message.id, id: @attachment.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_missing
  end
end
