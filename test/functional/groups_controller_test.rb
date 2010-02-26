require File.dirname(__FILE__) + '/../test_helper'

class GroupsControllerTest < ActionController::TestCase
  
  def setup
    @person, @other_person = Person.forge, Person.forge
    @group = Group.forge(:creator_id => @person.id, :category => 'Small Groups')
    @group.memberships.create(:person => @person, :admin => true)
  end
  
  should "show a group" do
    get :show, {:id => @group.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_tag :tag => 'h1', :content => Regexp.new(@group.name)
  end
  
  should "not show a group if group is private and user is not a member of the group" do
    @private_group = Group.forge(:private => true)
    get :show, {:id => @private_group.id}, {:logged_in_id => @person.id}
    assert_response :missing
  end
  
  should "not show a group if it is hidden" do
    @hidden_group = Group.forge(:hidden => true)
    get :show, {:id => @hidden_group.id}, {:logged_in_id => @person.id}
    assert_response :missing
  end
  
  should "show a hidden group if the user can manage groups" do
    @hidden_group = Group.forge(:hidden => true)
    @admin = Person.forge(:admin => Admin.create(:manage_groups => true))
    get :show, {:id => @hidden_group.id}, {:logged_in_id => @admin.id}
    assert_response :success
    assert_tag :tag => 'h1', :content => Regexp.new(@hidden_group.name)
  end
  
  should "list a person's groups" do
    get :index, {:person_id => @person.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 1, assigns(:person).groups.length
  end
  
  should "not list a person's hidden groups" do
    @group.update_attribute :hidden, true
    get :index, {:person_id => @person.id}, {:logged_in_id => @person.id}
    assert_no_tag :tag => 'tr', :attributes => {:class => 'grayed hidden-group'}
  end
  
  should "list a person's hidden groups if the user can manage groups" do
    @admin = Person.forge(:admin => Admin.create(:manage_groups => true))
    @group.update_attribute :hidden, true
    get :index, {:person_id => @person.id}, {:logged_in_id => @admin.id}
    assert_tag :tag => 'tr', :attributes => {:class => 'grayed hidden-group'}
  end
  
  should "search for groups by name" do
    Group.forge(:name => 'foo')
    get :index, {:name => 'foo'}, {:logged_in_id => @person.id}
    assert_equal 1, assigns(:groups).length
  end
  
  should "search for groups by category" do
    get :index, {:category => 'Small Groups'}, {:logged_in_id => @person.id}
    assert_equal 2, assigns(:groups).length
  end
  
  should "list a person's unapproved groups" do
    Group.delete_all
    @group = Group.forge(:creator_id => @person.id, :approved => false)
    @group.memberships.create(:person => @person, :admin => true)
    2.times { Group.forge(:approved => false) }
    get :index, nil, {:logged_in_id => @person.id}
    assert_equal 1, assigns(:unapproved_groups).length
  end
  
  should "list all unapproved groups if the user can manage groups" do
    @admin = Person.forge(:admin => Admin.create(:manage_groups => true))
    Group.delete_all
    2.times { Group.forge(:approved => false) }
    get :index, nil, {:logged_in_id => @admin.id}
    assert_equal 2, assigns(:unapproved_groups).length
  end
  
  should "add a group photo" do
    @group.photo = nil
    assert !@group.has_photo?
    post :update, {:id => @group.id, :group => {:photo => fixture_file_upload('files/image.jpg')}}, {:logged_in_id => @person.id}
    assert_redirected_to group_path(@group)
    assert Group.find(@group.id).has_photo?
  end
  
  should "remove a group photo" do
    @group.forge_photo
    assert @group.has_photo?
    post :update, {:id => @group.id, :group => {:photo => 'remove'}}, {:logged_in_id => @person.id}
    assert_redirected_to group_path(@group)
    assert !Group.find(@group.id).has_photo?
  end
  
  should "edit a group" do
    get :edit, {:id => @group.id}, {:logged_in_id => @person.id}
    assert_response :success
    post :update, {:id => @group.id, :group => {:name => 'test name', :category => 'test cat'}}, {:logged_in_id => @person.id}
    assert_redirected_to group_path(@group)
    assert_equal 'test name', @group.reload.name
    assert_equal 'test cat',  @group.category
  end
  
  should "not edit a group unless user is group admin or can manage groups" do
    get :edit, {:id => @group.id}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
    post :update, {:id => @group.id, :group => {:name => 'test name', :category => 'test cat'}}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
  end
  
  should "create a group pending approval" do
    get :new, nil, {:logged_in_id => @person.id}
    assert_response :success
    group_count = Group.count
    post :create, {:group => {:name => 'test name', :category => 'test cat'}}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_equal group_count+1, Group.count
    new_group = Group.last
    assert_equal 'test name', new_group.name
    assert_equal 'test cat',  new_group.category
    assert !new_group.approved?
  end
  
  should "create an approved group if user can manage groups" do
    @admin = Person.forge(:admin => Admin.create(:manage_groups => true))
    get :new, nil, {:logged_in_id => @admin.id}
    assert_response :success
    group_count = Group.count
    post :create, {:group => {:name => 'test name', :category => 'test cat'}}, {:logged_in_id => @admin.id}
    assert_response :redirect
    assert_equal group_count+1, Group.count
    new_group = Group.last
    assert_equal 'test name', new_group.name
    assert_equal 'test cat',  new_group.category
    assert new_group.approved?
  end
  
  should "not allow creation of groups if the site has reached limit" do
    Site.current.update_attribute(:max_groups, 1000)
    post :create, {:group => {:name => 'test name 1', :category => 'test cat 1'}}, {:logged_in_id => @person.id}
    assert_response :redirect
    Site.current.update_attribute(:max_groups, 1)
    post :create, {:group => {:name => 'test name 2', :category => 'test cat 2'}}, {:logged_in_id => @person.id}
    assert_response :unauthorized
    Site.current.update_attribute(:max_groups, nil)
    post :create, {:group => {:name => 'test name 3', :category => 'test cat 3'}}, {:logged_in_id => @person.id}
    assert_response :redirect
  end
  
end
