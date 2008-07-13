require File.dirname(__FILE__) + '/../test_helper'

class PhotosControllerTest < ActionController::TestCase

  def setup
    @family = Family.forge(:photo => true)
    @person = Person.forge(:photo => true)
  end

  should "show a family photo" do
    get :show, {:family_id => @family.id}, {:logged_in_id => @person}
    assert_response :success
  end
  
  should "show a family photo by size" do
    get :show, {:family_id => @family.id, :size => 'tn'}, {:logged_in_id => @person}
    assert_response :success
  end
   
  should "show a family photo by size method" do
    get :medium, {:family_id => @family.id}, {:logged_in_id => @person}
    assert_response :success
  end
  
  should "show a person photo" do
    get :show, {:person_id => @person.id}, {:logged_in_id => @person}
    assert_response :success
  end  
  
  should "show a person photo by size" do
    get :show, {:person_id => @person.id, :size => 'large'}, {:logged_in_id => @person}
    assert_response :success
  end

  should "not show a person photo if the logged in user cannot see the person" do
    @child = Person.forge(:birthday => 1.year.ago, :gender => 'girl', :photo => true)
    get :show, {:person_id => @child.id}, {:logged_in_id => @person}
    assert_response :missing
  end
  
  should "show a group photo" do
    @group = Group.forge(:photo => true)
    get :show, {:group_id => @group.id}, {:logged_in_id => @person}
    assert_response :success
  end  

  should "show a picture photo" do
    @album = Album.forge
    @picture = @album.forge(:picture)
    get :show, {:album_id => @album.id, :picture_id => @picture.id}, {:logged_in_id => @person}
    assert_response :success
  end

  should "show a recipe photo" do
    @recipe = Recipe.forge(:photo => true)
    get :show, {:recipe_id => @recipe.id}, {:logged_in_id => @person}
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
