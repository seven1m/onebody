require File.dirname(__FILE__) + '/../test_helper'

class PublicationsControllerTest < ActionController::TestCase
  
  def setup
    @person, @admin = Person.forge, Person.forge
    @admin.admin = Admin.create(:manage_publications => true)
    @publication = Publication.forge
  end
  
  should "list all publications" do
    get :index, nil, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 1, assigns(:publications).length
  end
  
  should "assign the Publications subscription group" do
    get :index, nil, {:logged_in_id => @person.id}
    assert_equal [Group.find_by_name('Publications')], assigns(:groups)
  end
  
  should "show (send data) for a publication" do
    get :show, {:id => @publication.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal File.read(@publication.file_path).length, @response.binary_content.length
  end
  
  should "create a new publication" do
    get :new, nil, {:logged_in_id => @admin.id}
    assert_response :success
    post :create, {
      :publication => {:name => 'test name', :description => 'test desc', :file => fixture_file_upload('files/attachment.pdf')}
    }, {:logged_in_id => @admin.id}
    assert_redirected_to publications_path
  end
  
  should "not create a new publication unless user is admin" do
    get :new, nil, {:logged_in_id => @person.id}
    assert_response :unauthorized
    post :create, {
      :publication => {:name => 'test name', :description => 'test desc', :file => fixture_file_upload('files/attachment.pdf')}
    }, {:logged_in_id => @person.id}
    assert_response :unauthorized
  end
  
  should "redirect to a new message upon publication upload" do
    pub_group = Group.find_by_name('Publications')
    post :create, {
      :publication => {:name => 'test name', :description => 'test desc', :file => fixture_file_upload('files/attachment.pdf')},
      :send_update_to_group_id => pub_group.id
    }, {:logged_in_id => @admin.id}
    assert_redirected_to new_message_path(:group_id => pub_group)
  end
  
  should "delete a publication" do
    post :destroy, {:id => @publication.id}, {:logged_in_id => @admin.id}
    assert_raise(ActiveRecord::RecordNotFound) do
      @publication.reload
    end
    assert_redirected_to publications_path
  end
  
  should "not delete a publication unless user is admin" do
    post :destroy, {:id => @publication.id}, {:logged_in_id => @person.id}
    assert_response :unauthorized
  end
  
end
