require File.dirname(__FILE__) + '/../test_helper'

class AlbumsControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = Person.forge, Person.forge
    @album = @person.forge(:album)
  end

  should "list all albums" do
    get :index, nil, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 1, assigns(:albums).length
  end

  should "showing an album should redirect to view its pictures" do
    get :show, {:id => @album.id}, {:logged_in_id => @person.id}
    assert_redirected_to album_pictures_path(@album)
  end

  should "create an album" do
    get :new, nil, {:logged_in_id => @person.id}
    assert_response :success
    post :create, {:album => {:name => 'test name', :description => 'test desc'}}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_equal 2, Album.count
    new_album = Album.last
    assert_equal 'test name', new_album.name
    assert_equal 'test desc', new_album.description
  end

  should "edit an album" do
    get :edit, {:id => @album.id}, {:logged_in_id => @person.id}
    assert_response :success
    post :update, {:id => @album.id, :album => {:name => 'test name', :description => 'test desc'}}, {:logged_in_id => @person.id}
    assert_redirected_to album_path(@album)
    assert_equal 'test name', @album.reload.name
    assert_equal 'test desc', @album.description
  end

  should "not edit an album unless user is owner or admin" do
    get :edit, {:id => @album.id}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
    post :update, {:id => @album.id, :album => {:name => 'test name', :description => 'test desc'}}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
  end

  should "delete an album" do
    post :destroy, {:id => @album.id}, {:logged_in_id => @person.id}
    assert_raise(ActiveRecord::RecordNotFound) do
      @album.reload
    end
    assert_redirected_to albums_path
  end

  should "not delete an album unless user is owner or admin" do
    post :destroy, {:id => @album.id}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
  end

end
