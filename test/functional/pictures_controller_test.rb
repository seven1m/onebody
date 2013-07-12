require_relative '../test_helper'

class PicturesControllerTest < ActionController::TestCase

  setup do
    @person = FactoryGirl.create(:person)
    @album = FactoryGirl.create(:album, owner: @person)
    @picture = FactoryGirl.create(:picture, album: @album, person: @person)
  end

  def add_pictures(how_many=2)
    @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
    @picture3 = FactoryGirl.create(:picture, album: @album, person: @person) unless how_many == 1
  end

  context '#index' do
    should 'list all pictures in an album' do
      get :index, {album_id: @album.id}, {logged_in_id: @person.id}
      assert_response :success
      assert_equal [@picture], assigns(:pictures)
    end
  end

  context '#show' do
    should 'display a picture' do
      get :show, {album_id: @album.id, id: @picture.id}, {logged_in_id: @person.id}
      assert_response :success
      assert_equal @picture, assigns(:picture)
    end
  end

  context '#next' do
    setup do
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
    end

    should 'redirect to next picture' do
      get :next, {album_id: @album.id, id: @picture.id}, {logged_in_id: @person.id}
      assert_redirected_to album_picture_path(@album, @picture2)
    end

    context 'given specified picture is last in album' do
      setup do
        get :next, {album_id: @album.id, id: @picture2.id}, {logged_in_id: @person.id}
      end

      should 'redirect to first picture' do
        assert_redirected_to album_picture_path(@album, @picture)
      end
    end
  end

  context '#prev' do
    setup do
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
    end

    should 'redirect to previous picture' do
      get :next, {album_id: @album.id, id: @picture2.id}, {logged_in_id: @person.id}
      assert_redirected_to album_picture_path(@album, @picture)
    end

    context 'given specified picture is first in album' do
      setup do
        get :next, {album_id: @album.id, id: @picture.id}, {logged_in_id: @person.id}
      end

      should 'redirect to last picture' do
        assert_redirected_to album_picture_path(@album, @picture2)
      end
    end
  end

  context '#create' do
    should 'create one picture' do
      post :create, {album: @album.name, pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
      assert_redirected_to album_pictures_path(@album)
      assert_equal "1 picture(s) saved", flash[:notice]
    end

    should 'create more than one picture' do
      post :create, {
        album: @album.name,
        pictures: [
          Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true),
          Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true),
          Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)
        ]
      }, {logged_in_id: @person.id}
      assert_redirected_to album_pictures_path(@album)
      assert_equal "3 picture(s) saved", flash[:notice]
    end

    should 'create a new album by name' do
      post :create, {album: 'My Stuff', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
      album = Album.last
      assert_equal 'My Stuff', album.name
      assert_redirected_to album_pictures_path(album)
      assert_equal '1 picture(s) saved', flash[:notice]
    end

    context 'given one bad image and one good image' do
      setup do
        post :create, {
          album: 'My Stuff',
          pictures: [
            Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true),
            Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.bmp'), 'image/bmp', true)
          ]
        }, {logged_in_id: @person.id}
      end

      should 'create one image and fail one image' do
        assert_equal '1 picture(s) saved<br/>1 not saved due to errors', flash[:notice]
      end
    end

    context 'group specified' do
      setup do
        @album = @person.albums.create(name: 'Existing Album')
        @group = FactoryGirl.create(:group)
      end

      context 'existing album name specified' do
        context 'user is not a group member' do
          should 'return forbidden' do
            post :create, {group_id: @group.id, album: 'Existing Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
            assert_response :forbidden
          end
        end

        context 'user is a group member' do
          setup do
            @group.memberships.create(person: @person)
          end

          should 'redirect to the album' do
            post :create, {group_id: @group.id, album: 'Existing Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
            assert_redirected_to @group
          end

          context 'group does not allow pictures' do
            setup do
              @group.update_attributes!(pictures: false)
            end

            should 'return forbidden' do
              post :create, {group_id: @group.id, album: 'Existing Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
              assert_response :forbidden
            end
          end
        end
      end
    end

    context 'group specified' do
      setup do
        @group = FactoryGirl.create(:group)
      end

      context 'new album name specified' do
        context 'user is not a group member' do
          should 'return forbidden' do
            post :create, {group_id: @group.id, album: 'New Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
            assert_response :forbidden
          end

          should 'not create an album' do
            assert_nil Album.find_by_name('New Album')
          end
        end

        context 'user is a group member' do
          setup do
            @group.memberships.create(person: @person)
          end

          should 'redirect to the group' do
            post :create, {group_id: @group.id, album: 'New Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
            assert_redirected_to @group
          end

          context 'group does not allow pictures' do
            setup do
              @group.update_attributes!(pictures: false)
            end

            should 'return forbidden' do
              post :create, {group_id: @group.id, album: 'New Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
              assert_response :forbidden
            end

            should 'not create an album' do
              assert_nil Album.find_by_name('New Album')
            end
          end
        end
      end
    end

    should 'use an existing album by name' do
      @album = @person.albums.create(name: 'Existing Album')
      album_count = Album.count
      post :create, {album: 'Existing Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
      assert_redirected_to album_pictures_path(@album)
      assert_equal album_count, Album.count
      assert_equal @album, Picture.last.album
      assert_equal '1 picture(s) saved', flash[:notice]
    end

    should 'use an existing album by id' do
      @album = FactoryGirl.create(:album, owner: @person)
      album_count = Album.count
      post :create, {album_id: @album.id, pictures: [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)]}, {logged_in_id: @person.id}
      assert_redirected_to album_pictures_path(@album)
      assert_equal album_count, Album.count
      assert_equal @album, Picture.last.album
      assert_equal '1 picture(s) saved', flash[:notice]
    end
  end

  context '#update' do
    should 'select a picture as an album cover' do
      add_pictures(1)
      post :update, {album_id: @album.id, id: @picture.id, cover: 'true'}, {logged_in_id: @person.id}
      assert_redirected_to album_picture_path(@album, @picture)
      assert @picture.reload.cover
      post :update, {album_id: @album.id, id: @picture2.id, cover: 'true'}, {logged_in_id: @person.id}
      assert_redirected_to album_picture_path(@album, @picture2)
      assert !@picture.reload.cover
      assert @picture2.reload.cover
    end

    should 'rotate a picture' do
      @picture = FactoryGirl.create(:picture, :with_file, album: @album)
      post :update, {album_id: @album.id, id: @picture.id, degrees: '90'}, {logged_in_id: @person.id}
      assert_redirected_to album_picture_path(@album, @picture)
    end
  end

  context '#destroy' do
    should 'delete a picture' do
      post :destroy, {album_id: @album.id, id: @picture.id}, {logged_in_id: @person.id}
      assert_raise(ActiveRecord::RecordNotFound) do
        @picture.reload
      end
      assert_redirected_to album_path(@album)
    end
  end

end
