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
    get :show, {:message_id => @message.id, :id => @attachment.id}, {:logged_in_id => @person.id}
    assert_response :success
  end
  
  should "not show an attachment unless the person can see what it is attached to" do
    get :show, {:message_id => @message.id, :id => @attachment.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "show the new page attachment form" do
    @admin = Person.forge(:admin => Admin.create(:edit_pages => true))
    get :new, {:page_id => pages(:foo).id}, {:logged_in_id => @admin.id}
    assert_response :success
    assert_equal pages(:foo), assigns(:page)
  end
  
  should "create a new page attachment" do
    @admin = Person.forge(:admin => Admin.create(:edit_pages => true))
    post :create, {:attachment => {:page_id => pages(:foo).id, :file => fixture_file_upload('files/attachment.pdf')}, :from => edit_page_path(pages(:foo))}, {:logged_in_id => @admin.id}
    assert_redirected_to edit_page_path(pages(:foo))
    assert_equal 1, pages(:foo).attachments.count
  end
  
  should "not create a page attachment unless user is admin" do
    get :new, {:page_id => pages(:foo).id}, {:logged_in_id => @person.id}
    assert_response :unauthorized
    post :create, {:attachment => {:page_id => pages(:foo).id, :file => fixture_file_upload('files/attachment.pdf')}, :from => edit_page_path(pages(:foo))}, {:logged_in_id => @person.id}
    assert_response :unauthorized
  end
  
  should "delete a page attachment" do
    @admin = Person.forge(:admin => Admin.create(:edit_pages => true))
    @attachment = Attachment.create_from_file(:page_id => pages(:foo).id, :file => fixture_file_upload('files/attachment.pdf'))
    post :destroy, {:id => @attachment.id, :from => edit_page_path(pages(:foo))}, {:logged_in_id => @admin.id}
    assert_redirected_to edit_page_path(pages(:foo))
    assert_raise(ActiveRecord::RecordNotFound) do
      @attachment.reload
    end
  end
  
  should "not delete a page attachment unless user is admin" do
    @attachment = Attachment.create_from_file(:page_id => pages(:foo).id, :file => fixture_file_upload('files/attachment.pdf'))
    post :destroy, {:id => @attachment.id, :from => edit_page_path(pages(:foo))}, {:logged_in_id => @person.id}
    assert_response :unauthorized
  end

end
