require_relative '../rails_helper'

describe AttachmentsController, type: :controller do

  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group = Group.create! name: 'Some Group', category: 'test', private: true
    @group.memberships.create! person: @person
    @message = Message.create_with_attachments(
      {group: @group, person: @person, subject: 'subject', body: 'body'},
      [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true)]
    )
    @attachment = @message.attachments.first
  end

  it "should show an attachment" do
    get :show, {message_id: @message.id, id: @attachment.id}, {logged_in_id: @person.id}
    expect(response).to be_success
  end

  it "should not show an attachment unless the person can see what it is attached to" do
    get :show, {message_id: @message.id, id: @attachment.id}, {logged_in_id: @other_person.id}
    expect(response).to be_missing
  end

  it "should create a new group attachment" do
    @admin = FactoryGirl.create(:person, :admin_manage_groups)
    post :create, {attachment: {group_id: @group.id, file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true)}}, {logged_in_id: @admin.id}
    expect(response).to redirect_to(group_attachments_path(@group))
    expect(@group.attachments.count).to eq(1)
  end

  it "should not create a group attachment unless user is admin" do
    get :new, {group_id: @group.id}, {logged_in_id: @person.id}
    expect(response).to be_unauthorized
    post :create, {attachment: {group_id: @group.id, file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true)}}, {logged_in_id: @person.id}
    expect(response).to be_unauthorized
  end

  it "should delete a group attachment" do
    @admin = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    @attachment = Attachment.create_from_file(group_id: @group.id, file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true))
    post :destroy, {id: @attachment.id, from: edit_group_path(@group)}, {logged_in_id: @admin.id}
    expect(response).to redirect_to(edit_group_path(@group))
    expect { @attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should not delete a group attachment unless user is admin" do
    @attachment = Attachment.create_from_file(group_id: @group.id, file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true))
    post :destroy, {id: @attachment.id}, {logged_in_id: @person.id}
    expect(response).to be_unauthorized
  end
end
