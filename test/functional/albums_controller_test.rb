require_relative '../test_helper'

class AlbumsControllerTest < ActionController::TestCase

  def setup
    @person, @friend, @stranger = FactoryGirl.create_list(:person, 3)
    Friendship.create!(person: @person, friend: @friend)
    @album = FactoryGirl.create(:album, person: @person)
    @album2 = FactoryGirl.create(:album, person: @friend)
  end

  context '#index' do
    should 'list all albums by ' do
      get :index, nil, {logged_in_id: @person.id}
      assert_response :success
      assert_equal [@album, @album2], assigns(:albums)
    end

    should 'list public albums' do
      public_album = FactoryGirl.create(:album, is_public: true)
      get :index, nil, {logged_in_id: @person.id}
      assert_response :success
      assert_include assigns(:albums), public_album
    end

    should 'list albums for friends' do
      public_album = FactoryGirl.create(:album, is_public: true)
      get :index, nil, {logged_in_id: @person.id}
      assert_response :success
      assert_include assigns(:albums), public_album
    end

    should 'list all albums by person' do
      get :index, {person_id: @person.id}, {logged_in_id: @person.id}
      assert_response :success
      assert_equal [@album], assigns(:albums)
    end

    context 'listing albums for invisible user' do
      setup do
        @stranger.update_attributes!(visible: false)
      end

      should 'return unauthorized' do
        assert !@person.can_see?(@stranger)
        get :index, {person_id: @stranger.id}, {logged_in_id: @person.id}
        assert_response :unauthorized
      end
    end

    context 'album in a group' do
      setup do
        @group = FactoryGirl.create(:group)
        @album2.update_attributes!(group: @group)
        @group.memberships.create!(person: @person)
      end

      should 'list all albums by group' do
        get :index, {group_id: @group.id}, {logged_in_id: @person.id}
        assert_response :success
        assert_equal [@album2], assigns(:albums)
      end
    end
  end

  context '#show' do
    should "showing an album should redirect to view its pictures" do
      get :show, {id: @album.id}, {logged_in_id: @person.id}
      assert_redirected_to album_pictures_path(@album)
    end
  end

  context '#create' do
    should 'create an album' do
      get :new, nil, {logged_in_id: @person.id}
      assert_response :success
      before = Album.count
      post :create, {album: {group_id: nil, name: 'test name', description: 'test desc', is_public: false}}, {logged_in_id: @person.id}
      assert_response :redirect
      assert_equal before+1, Album.count
      new_album = Album.last
      assert_equal 'test name', new_album.name
      assert_equal 'test desc', new_album.description
    end

    context 'add album to a group' do
      setup do
        @group = FactoryGirl.create(:group)
      end

      context 'user is a member of the group' do
        setup do
          @group.memberships.create!(person: @person)
        end

        should 'create an album' do
          post :create, {album: {group_id: @group.id, name: 'test name'}}, {logged_in_id: @person.id}
          assert_response :redirect
        end
      end

      context 'user is not a member of the group' do
        should 'return unauthorized' do
          post :create, {album: {group_id: @group.id, name: 'test name'}}, {logged_in_id: @person.id}
          assert_response :unauthorized
        end
      end

      context 'group does not have pictures enabled' do
        setup do
          @group.update_attributes!(pictures: false)
        end

        should 'return unauthorized' do
          post :create, {album: {group_id: @group.id, name: 'test name'}}, {logged_in_id: @person.id}
          assert_response :unauthorized
        end
      end

      context 'indicated to remove owner' do
        context 'user is not an admin' do
          should 'still save owner (person) on album' do
            Album.delete_all
            post :create, {album: {name: 'test name'}, remove_owner: true}, {logged_in_id: @person.id}
            assert_equal @person, Album.last.person
          end
        end

        context 'user is an admin' do
          setup do
            @person.update_attributes(admin: Admin.create!(manage_pictures: true))
          end

          should 'not save owner (person) on album' do
            Album.delete_all
            post :create, {album: {name: 'test name'}, remove_owner: true}, {logged_in_id: @person.id}
            assert_nil Album.last.person
          end
        end
      end
    end
  end

  context '#update' do
    should 'edit the album' do
      get :edit, {id: @album.id}, {logged_in_id: @person.id}
      assert_response :success
      post :update, {id: @album.id, album: {name: 'test name', description: 'test desc'}}, {logged_in_id: @person.id}
      assert_redirected_to album_path(@album)
      assert_equal 'test name', @album.reload.name
      assert_equal 'test desc', @album.description
    end

    context 'user does not own album' do
      setup do
        @stranger = FactoryGirl.create(:person)
      end

      should 'return unauthorized' do
        get :edit, {id: @album.id}, {logged_in_id: @stranger.id}
        assert_response :unauthorized
        post :update, {id: @album.id, album: {name: 'test name', description: 'test desc'}}, {logged_in_id: @stranger.id}
        assert_response :unauthorized
      end

      context 'user is admin' do
        setup do
          @stranger.update_attributes(admin: Admin.create!(manage_pictures: true))
        end

        should 'edit the album' do
          get :edit, {id: @album.id}, {logged_in_id: @stranger.id}
          assert_response :success
          post :update, {id: @album.id, album: {name: 'test name', description: 'test desc'}}, {logged_in_id: @stranger.id}
          assert_response :redirect
        end
      end
    end
  end

  context '#destroy' do
    should 'delete the album' do
      post :destroy, {id: @album.id}, {logged_in_id: @person.id}
      assert_raise(ActiveRecord::RecordNotFound) do
        @album.reload
      end
      assert_redirected_to albums_path
    end

    context 'user does not own album' do
      setup do
        @stranger = FactoryGirl.create(:person)
      end

      should 'return unauthorized' do
        post :destroy, {id: @album.id}, {logged_in_id: @stranger.id}
        assert_response :unauthorized
      end

      context 'user is admin' do
        setup do
          @stranger.update_attributes(admin: Admin.create!(manage_pictures: true))
        end

        should 'delete the album' do
          post :destroy, {id: @album.id}, {logged_in_id: @stranger.id}
          assert_response :redirect
        end
      end
    end
  end

end
