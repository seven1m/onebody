require File.dirname(__FILE__) + '/../test_helper'

class GroupsControllerTest < ActionController::TestCase
  
  def setup
    @person, @other_person = Person.forge, Person.forge
    @group = Group.forge(:creator_id => @person.id, :category => 'Small Groups')
    @group.memberships.create(:person => @person, :admin => true)
  end
  
  should "show a group"
  
  should "not show a group if group is private and user is not a member of the group"
  
  should "not show a group if it is hidden"
  
  should "show a hidden group if the user can manage groups"
  
  should "list a person's groups"
  
  should "not list a person's hidden groups"
  
  should "list a person's hidden groups if the user can manage groups"
  
  should "search for groups by name"
  
  should "search for groups by category"
  
  should "list a person's unapproved groups"
  
  should "list all unapproved groups if the user can manage groups"
  
  should "add a group photo"
  
  should "remove a group photo"
  
  should "edit a group"
  
  should "not edit a group unless user is group admin or can manage groups"
  
  should "create a group pending approval" do
    get :new, nil, {:logged_in_id => @person}
    assert_response :success
    group_count = Group.count
    post :create, {:group => {:name => 'test name', :category => 'test cat'}}, {:logged_in_id => @person}
    assert_response :redirect
    assert_equal group_count+1, Group.count
    new_group = Group.last
    assert_equal 'test name', new_group.name
    assert_equal 'test cat',  new_group.category
    assert !new_group.approved?
  end
  
  should "create an approved group" do
    @admin = Person.forge(:admin => Admin.create(:manage_groups => true))
    get :new, nil, {:logged_in_id => @admin}
    assert_response :success
    group_count = Group.count
    post :create, {:group => {:name => 'test name', :category => 'test cat'}}, {:logged_in_id => @admin}
    assert_response :redirect
    assert_equal group_count+1, Group.count
    new_group = Group.last
    assert_equal 'test name', new_group.name
    assert_equal 'test cat',  new_group.category
    assert new_group.approved?
  end
#  
#  should "edit an album" do
#    get :edit, {:id => @album.id}, {:logged_in_id => @person}
#    assert_response :success
#    post :update, {:id => @album.id, :album => {:name => 'test name', :description => 'test desc'}}, {:logged_in_id => @person}
#    assert_redirected_to album_path(@album)
#    assert_equal 'test name', @album.reload.name
#    assert_equal 'test desc', @album.description
#  end
#  
#  should "not edit an album unless user is owner or admin" do
#    get :edit, {:id => @album.id}, {:logged_in_id => @other_person}
#    assert_response :unauthorized
#    post :update, {:id => @album.id, :album => {:name => 'test name', :description => 'test desc'}}, {:logged_in_id => @other_person}
#    assert_response :unauthorized
#  end
#  
#  should "delete an album" do
#    post :destroy, {:id => @album.id}, {:logged_in_id => @person}
#    assert_raise(ActiveRecord::RecordNotFound) do
#      @album.reload
#    end
#    assert_redirected_to albums_path
#  end
#  
#  should "not delete an album unless user is owner or admin" do
#    post :destroy, {:id => @album.id}, {:logged_in_id => @other_person}
#    assert_response :unauthorized
#  end
  
end
