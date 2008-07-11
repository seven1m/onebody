require File.dirname(__FILE__) + '/../test_helper'

class RecipesControllerTest < ActionController::TestCase
  
  def setup
    @person, @other_person = Person.forge, Person.forge
    @recipe = @person.forge(:recipe)
  end
  
  should "list all recipes" do
    get :index, nil, {:logged_in_id => @person}
    assert_response :success
    assert_equal 1, assigns(:recipes).length
  end
  
  should "show a recipe" do
    get :show, {:id => @recipe.id}, {:logged_in_id => @person}
    assert_response :success
    assert_equal @recipe, assigns(:recipe)
  end
  
  should "create a recipe" do
    get :new, nil, {:logged_in_id => @person}
    assert_response :success
    post :create, {:recipe => {:title => 'test title', :ingredients => 'test ing', :directions => 'test dir'}}, {:logged_in_id => @person}
    assert_equal 2, Recipe.count
    new_recipe = Recipe.last
    assert_redirected_to recipe_path(new_recipe)
    assert_equal 'test title', new_recipe.title
    assert_equal 'test ing', new_recipe.ingredients
    assert_equal 'test dir', new_recipe.directions
  end
  
  should "edit a recipe" do
    get :edit, {:id => @recipe.id}, {:logged_in_id => @person}
    assert_response :success
    post :update, {:id => @recipe.id, :recipe => {:title => 'test title', :ingredients => 'test ing', :directions => 'test dir'}}, {:logged_in_id => @person}
    assert_redirected_to recipe_path(@recipe)
    assert_equal 'test title', @recipe.reload.title
    assert_equal 'test ing', @recipe.ingredients
    assert_equal 'test dir', @recipe.directions
  end
  
  should "not edit a recipe unless user is owner or admin" do
    get :edit, {:id => @recipe.id}, {:logged_in_id => @other_person}
    assert_response :unauthorized
    post :update, {:id => @recipe.id, :recipe => {:title => 'test title', :ingredients => 'test ing', :directions => 'test dir'}}, {:logged_in_id => @other_person}
    assert_response :unauthorized
  end
  
  should "delete a recipe" do
    post :destroy, {:id => @recipe.id}, {:logged_in_id => @person}
    assert_raise(ActiveRecord::RecordNotFound) do
      @recipe.reload
    end
    assert_redirected_to recipes_path
  end
  
  should "not delete a recipe unless user is owner or admin" do
    post :destroy, {:id => @recipe.id}, {:logged_in_id => @other_person}
    assert_response :unauthorized
  end
  
end
