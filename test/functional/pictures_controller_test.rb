require_relative '../test_helper'

class PicturesControllerTest < ActionController::TestCase

  def setup
    @person = FactoryGirl.create(:person)
    @album = FactoryGirl.create(:album, :person => @person)
    @picture  = FactoryGirl.create(:picture, :album => @album, :person => @person)
  end

  def add_pictures(how_many=2)
    @picture2 = FactoryGirl.create(:picture, :album => @album, :person => @person)
    @picture3 = FactoryGirl.create(:picture, :album => @album, :person => @person) unless how_many == 1
  end

  should "list all pictures in an album" do
    add_pictures
    get :index, {:album_id => @album.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 3, assigns(:pictures).length
  end

  should "display a picture" do
    get :show, {:album_id => @album.id, :id => @picture.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal @picture, assigns(:picture)
  end

  should "handle prev and next redirection" do
    add_pictures
    # next in line
    get :next, {:album_id => @album.id, :id => @picture2.id}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture3)
    # next in line, loop to beginning
    get :next, {:album_id => @album.id, :id => @picture3.id}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture)
    # previous in line
    get :prev, {:album_id => @album.id, :id => @picture2.id}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture)
    # previous in line, loop to end
    get :prev, {:album_id => @album.id, :id => @picture.id}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture3)
  end

  should "rotate a picture" do
    post :update, {:album_id => @album.id, :id => @picture.id, :degrees => '90'}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture)
  end

  should "select a picture as an album cover" do
    add_pictures(1)
    post :update, {:album_id => @album.id, :id => @picture.id, :cover => 'true'}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture)
    assert @picture.reload.cover
    post :update, {:album_id => @album.id, :id => @picture2.id, :cover => 'true'}, {:logged_in_id => @person.id}
    assert_redirected_to album_picture_path(@album, @picture2)
    assert !@picture.reload.cover
    assert @picture2.reload.cover
  end

  should "create one picture" do
    post :create, {:album => @album.name, :pictures => [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {:logged_in_id => @person.id}
    assert_redirected_to album_pictures_path(@album)
    assert_equal "1 picture(s) saved", flash[:notice]
  end

  should "create more than one picture" do
    post :create, {
      :album => @album.name,
      :pictures => [
        Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true),
        Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true),
        Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)
      ]
    }, {:logged_in_id => @person.id}
    assert_redirected_to album_pictures_path(@album)
    assert_equal "3 picture(s) saved", flash[:notice]
  end

  should "delete a picture" do
    post :destroy, {:album_id => @album.id, :id => @picture.id}, {:logged_in_id => @person.id}
    assert_raise(ActiveRecord::RecordNotFound) do
      @picture.reload
    end
    assert_redirected_to album_path(@album)
  end

  should "create a new album if specified" do
    post :create, {:album => 'My Stuff', :pictures => [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {:logged_in_id => @person.id}
    album = Album.last
    assert_equal 'My Stuff', album.name
    assert_redirected_to album_pictures_path(album)
    assert_equal "1 picture(s) saved", flash[:notice]
  end

  should "use an existing album if specified" do
    @album = @person.albums.create(:name => 'Existing Album')
    album_count = Album.count
    post :create, {:album => 'Existing Album', :pictures => [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {:logged_in_id => @person.id}
    assert_equal album_count, Album.count
    assert_equal @album, Picture.last.album
    assert_redirected_to album_pictures_path(@album)
    assert_equal "1 picture(s) saved", flash[:notice]
  end

end
