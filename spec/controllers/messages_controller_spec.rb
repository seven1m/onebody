require_relative '../rails_helper'

describe MessagesController, type: :controller do
  render_views

  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group = Group.create! name: 'Some Group', category: 'test'
    @group.memberships.create! person: @person
    (@peers = FactoryGirl.create_list(:person, 3)).each do |peer|
      @group.memberships.create! person: peer
    end
  end

  it 'should delete a group message' do
    @message = @group.messages.create! subject: 'Just a Test', body: 'body', person: @person
    post :destroy,
         params: { id: @message.id },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
  end

  it 'should create new private messages' do
    ActionMailer::Base.deliveries = []
    get :new,
        params: { to_person_id: @person.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_success
    post :create,
         params: { message: { to_person_id: @person.id, subject: 'Hello There', body: 'body' } },
         session: { logged_in_id: @other_person.id }
    expect(response).to be_success
    assert_select 'body', /message.+sent/
    expect(ActionMailer::Base.deliveries).to be_any
  end

  it 'should render preview of private message' do
    ActionMailer::Base.deliveries = []
    post :create,
         params: { format: 'js', preview: true, message: { to_person_id: @person.id, subject: 'Hello There', body: 'body' } },
         session: { logged_in_id: @other_person.id }
    expect(response).to be_success
    expect(response).to render_template('create')
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'should create new group messages' do
    ActionMailer::Base.deliveries = []
    get :new,
        params: { group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    post :create,
         params: { message: { group_id: @group.id, subject: 'Hello There', body: 'body' } },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    expect(response).to redirect_to(group_path(@group))
    expect(flash[:notice]).to match(/has been sent/)
    expect(ActionMailer::Base.deliveries).to be_any
  end

  it 'should render preview of group message' do
    ActionMailer::Base.deliveries = []
    post :create,
         params: { format: 'js', preview: true, message: { group_id: @group.id, subject: 'Hello There', body: 'body' } },
         session: { logged_in_id: @person.id }
    expect(response).to be_success
    expect(response).to render_template('create')
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'should not allow someone to post to a group they do not belong to unless they are an admin' do
    get :new,
        params: { group_id: @group.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_forbidden
    post :create,
         params: { message: { group_id: @group.id, subject: 'Hello There', body: 'body' } },
         session: { logged_in_id: @other_person.id }
    expect(response).to be_forbidden
  end

  it 'should create new group messages with an attachment' do
    ActionMailer::Base.deliveries = []
    get :new,
        params: { group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    post :create,
         params: { files: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'),
                                                        'application/pdf', true)],
                   message: { group_id: @group.id, subject: 'Hello There', body: 'body' } },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    expect(response).to redirect_to(group_path(@group))
    expect(flash[:notice]).to match(/has been sent/)
    expect(ActionMailer::Base.deliveries).to be_any
    expect(Message.last.attachments.count).to eq(1)
  end

  it 'should create new private messages with an attachment' do
    ActionMailer::Base.deliveries = []
    get :new,
        params: { to_person_id: @person.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_success
    post :create,
         params: { files: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'),
                                                        'application/pdf', true)],
                   message: { to_person_id: @person.id, subject: 'Hello There', body: 'body' } },
         session: { logged_in_id: @person.id }
    expect(response).to be_success
    assert_select 'body', /message.+sent/
    expect(ActionMailer::Base.deliveries).to be_any
    expect(Message.last.attachments.count).to eq(1)
  end

  it 'should not allow parent_id on message user cannot see' do
    @message = FactoryGirl.create(:message, to: @other_person)
    get :new,
        params: { parent_id: @message.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_forbidden
    post :create,
         params: { message: { to_person_id: @other_person.id, subject: 'Hello There', body: 'body', parent_id: @message.id } },
         session: { logged_in_id: @person.id }
    expect(response).to be_forbidden
  end

  it 'should show a message' do
    @message = @group.messages.create!(person: @person, subject: 'test subject', body: 'test body')
    get :show,
        params: { id: @message.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
  end

  it 'should show a message with an attachment' do
    @message = Message.create_with_attachments(
      { group: @group, person: @person, subject: 'test subject', body: 'test body' },
      [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true)]
    )
    @attachment = @message.attachments.first
    get :show,
        params: { id: @message.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    assert_select 'body', /attachment\.pdf/
  end

  it 'should send message to members of group that are selected' do
    post :create,
         params: { message: { member_ids: [@peers[0].id, @peers[2].id], subject: 'is peer1 OK?',
                              body: 'peer1 needs prayer', group_id: @group.id } },
         session: { logged_in_id: @person.id }
    expect(response).to redirect_to(@group)
  end
end
