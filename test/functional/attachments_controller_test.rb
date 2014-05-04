require_relative '../test_helper'

class AttachmentsControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group = Group.create! name: 'Some Group', category: 'test'
    @group.memberships.create! person: @person
    @message = Message.create_with_attachments(
      {group: @group, person: @person, subject: 'subject', body: 'body'},
      [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)]
    )
    @attachment = @message.attachments.first
  end

  should "show an attachment" do
    get :show, {message_id: @message.id, id: @attachment.id}, {logged_in_id: @person.id}
    assert_response :success
  end

  should "not show an attachment unless the person can see what it is attached to" do
    get :show, {message_id: @message.id, id: @attachment.id}, {logged_in_id: @other_person.id}
    assert_response :missing
  end

  should "create a new group attachment" do
    @admin = FactoryGirl.create(:person, :admin_manage_groups)
    post :create, {attachment: {group_id: @group.id, file: Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)}}, {logged_in_id: @admin.id}
    assert_redirected_to edit_group_path(@group, anchor: 'attachments')
    assert_equal 1, @group.attachments.count
  end

  should "not create a group attachment unless user is admin" do
    get :new, {group_id: @group.id}, {logged_in_id: @person.id}
    assert_response :unauthorized
    post :create, {attachment: {group_id: @group.id, file: Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)}}, {logged_in_id: @person.id}
    assert_response :unauthorized
  end

  should "delete a group attachment" do
    @admin = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    @attachment = Attachment.create_from_file(group_id: @group.id, file: Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true))
    post :destroy, {id: @attachment.id, from: edit_group_path(@group)}, {logged_in_id: @admin.id}
    assert_redirected_to edit_group_path(@group)
    assert_raise(ActiveRecord::RecordNotFound) do
      @attachment.reload
    end
  end

  should "not delete a group attachment unless user is admin" do
    @attachment = Attachment.create_from_file(group_id: @group.id, file: Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true))
    post :destroy, {id: @attachment.id}, {logged_in_id: @person.id}
    assert_response :unauthorized
  end
end
