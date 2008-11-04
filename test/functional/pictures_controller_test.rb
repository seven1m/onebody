require File.dirname(__FILE__) + '/../test_helper'

class PicturesControllerTest < ActionController::TestCase

  def setup
    @person = Person.forge
    @album = @person.forge(:album)
    @picture  = @album.forge(:picture, :person_id => @person.id)
    @picture2 = @album.forge(:picture, :person_id => @person.id)
    @picture3 = @album.forge(:picture, :person_id => @person.id)
  end
  
  should "list all pictures in an album" do
    get :index, {:album_id => @album.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 3, assigns(:pictures).length
  end
  
  should "display a picture" do
    get :show, {:album_id => @album.id, :id => @picture.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal @picture, assigns(:picture)
  end
  
  should "redirect to the next picture" do
    # next in line
    get :next, {:album_id => @album.id, :id => @picture2.id}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture3)
    # loop to beginning
    get :next, {:album_id => @album.id, :id => @picture3.id}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture)
  end
  
  should "redirect to the previous picture" do
    # previous in line
    get :prev, {:album_id => @album.id, :id => @picture2.id}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture)
    # loop to end
    get :prev, {:album_id => @album.id, :id => @picture.id}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture3)
  end
  
  should "rotate a picture" do
    post :update, {:album_id => @album.id, :id => @picture.id, :degrees => '90'}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture)
  end
  
  should "select a picture as an album cover" do
    post :update, {:album_id => @album.id, :id => @picture.id, :cover => 'true'}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture)
    assert @picture.reload.cover
    post :update, {:album_id => @album.id, :id => @picture2.id, :cover => 'true'}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture2)
    assert !@picture.reload.cover
    assert @picture2.reload.cover
  end
  
  should "create one picture" do
    post :create, {:album_id => @album.id, :picture1 => fixture_file_upload('files/image.jpg')}, {:logged_in_id => @person.id}
    assert_redirected_to album_path(@album)
    assert_equal "1 picture(s) saved", flash[:notice]
  end
  
  should "create more than one picture" do
    post :create, {
      :album_id => @album.id,
      :picture1 => fixture_file_upload('files/image.jpg'),
      :picture2 => fixture_file_upload('files/image.jpg'),
      :picture3 => fixture_file_upload('files/image.jpg')
    }, {:logged_in_id => @person.id}
    assert_redirected_to album_path(@album)
    assert_equal "3 picture(s) saved", flash[:notice]
  end
  
  should "delete a picture" do
    post :destroy, {:album_id => @album.id, :id => @picture.id}, {:logged_in_id => @person.id}
    assert_raise(ActiveRecord::RecordNotFound) do
      @picture.reload
    end
    assert_redirected_to album_path(@album)
  end

end
