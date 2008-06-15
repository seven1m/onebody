require File.dirname(__FILE__) + '/../test_helper'

class PhotosControllerTest < ActionController::TestCase

  def setup
    @family = Family.forge(:photo => true)
    @person = Person.forge(:photo => true)
  end

  should "show a family photo by id and type" do
    get :show, {:id => @family.id, :type => 'family'}, {:logged_in_id => @person}
    assert_response :success
  end
  
  should "show a family photo by id and type and size" do
    get :show, {:id => @family.id, :size => 'tn', :type => 'family'}, {:logged_in_id => @person}
    assert_response :success
  end
   
  should "show a family photo by family_id and size method" do
    get :medium, {:family_id => @family.id}, {:logged_in_id => @person}
    assert_response :success
  end
  
  should "show a person photo by id and type" do
    get :show, {:id => @person.id, :type => 'person'}, {:logged_in_id => @person}
    assert_response :success
  end  
  
  should "show a person photo by id and type and size" do
    get :show, {:id => @person.id, :size => 'large', :type => 'person'}, {:logged_in_id => @person}
    assert_response :success
  end

  should "not show a person photo if the logged in user cannot see the person" do
    @child = Person.forge(:birthday => 1.year.ago, :gender => 'girl', :photo => true)
    get :show, {:id => @child.id, :type => 'person'}, {:logged_in_id => @person}
    assert_response :missing
  end
  
  should "show a group photo by id and type" do
    @group = Group.forge(:photo => true)
    get :show, {:id => @group.id, :type => 'group'}, {:logged_in_id => @person}
    assert_response :success
  end  

  should "show a picture photo by id and type" do
    @picture = Picture.forge
    get :show, {:id => @picture.id, :type => 'picture'}, {:logged_in_id => @person}
    assert_response :success
  end

  should "show a recipe photo by id and type" do
    @recipe = Recipe.forge(:photo => true)
    get :show, {:id => @recipe.id, :type => 'recipe'}, {:logged_in_id => @person}
    assert_response :success
  end
  
  should "update a photo" do
    post :update, {:family_id => @person.family.id, :photo => fixture_file_upload('files/family.jpg')},
      {:logged_in_id => @person}
    assert_response :redirect
  end
  
  should "not update a photo unless user can edit the object" do
    post :update, {:family_id => @family.id, :photo => fixture_file_upload('files/family.jpg')},
      {:logged_in_id => @person}
    assert_response :error
  end
  
  should "delete a photo" do
    post :destroy, {:family_id => @person.family.id}, {:logged_in_id => @person}
    assert_response :redirect
  end
  
  should "not delete a photo unless user can edit the object" do
    post :destroy, {:family_id => @family.id}, {:logged_in_id => @person}
    assert_response :error
  end
  
end