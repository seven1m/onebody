require_relative '../test_helper'

class AlbumsControllerTest < ActionController::TestCase

  def setup
    @user = FactoryGirl.create(:person)
    #@stranger = FactoryGirl.create(:person)
    #@person = @user
    #@album = FactoryGirl.create(:album, owner: @person)
    #@album2 = FactoryGirl.create(:album, owner: @friend)
  end

  context '#index' do
    context 'shallow route' do
      context 'given a public album' do
        setup do
          @public_album = FactoryGirl.create(:album, is_public: true)
          get :index, nil, {logged_in_id: @user.id}
        end

        should 'list public albums' do
          assert_include assigns(:albums), @public_album
        end
      end

      context 'given an album owned by a friend' do
        setup do
          @friend = FactoryGirl.create(:person)
          Friendship.create!(person: @user, friend: @friend)
          @friend_album = FactoryGirl.create(:album, owner: @friend)
          get :index, nil, {logged_in_id: @user.id}
        end

        should 'list albums for friends' do
          assert_include assigns(:albums), @friend_album
        end
      end

      context 'given an album owned by a stranger' do
        setup do
          @stranger_album = FactoryGirl.create(:album)
          get :index, nil, {logged_in_id: @user.id}
        end

        should 'not list albums for strangers' do
          assert_not_include assigns(:albums), @stranger_album
        end
      end
    end

    context 'nested route on person' do
      setup do
        @album = FactoryGirl.create(:album, owner: @user)
      end

      should 'list all albums by person' do
        get :index, {person_id: @user.id}, {logged_in_id: @user.id}
        assert_response :success
        assert_equal [@album], assigns(:albums)
      end

      context 'listing albums for invisible user' do
        setup do
          @stranger = FactoryGirl.create(:person, visible: false)
          @album = FactoryGirl.create(:album, owner: @stranger)
        end

        should 'return unauthorized' do
          assert !@user.can_see?(@stranger)
          get :index, {person_id: @stranger.id}, {logged_in_id: @user.id}
          assert_response :unauthorized
        end
      end
    end

    #context 'album in a group' do
      #setup do
        #@group = FactoryGirl.create(:group)
        #@album2.update_attributes!(group: @group)
        #@group.memberships.create!(person: @person)
      #end

      #should 'list all albums by group' do
        #get :index, {group_id: @group.id}, {logged_in_id: @person.id}
        #assert_response :success
        #assert_equal [@album2], assigns(:albums)
      #end
    #end
  end

  context '#show' do
    context 'album owned by user' do
      setup do
        @album = FactoryGirl.create(:album, owner: @user)
      end

      should "showing an album should redirect to view its pictures" do
        get :show, {id: @album.id}, {logged_in_id: @user.id}
        assert_redirected_to album_pictures_path(@album)
      end
    end
  end

  context '#create' do
    should 'create an album' do
      get :new, nil, {logged_in_id: @user.id}
      assert_response :success
      before = Album.count
      post :create, {album: {name: 'test name', description: 'test desc', is_public: false}}, {logged_in_id: @user.id}
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
          @group.memberships.create!(person: @user)
        end

        should 'create an album' do
          post :create, {album: {owner_type: 'Group', owner_id: @group.id, name: 'test name'}}, {logged_in_id: @user.id}
          assert_response :redirect
        end
      end

      context 'user is not a member of the group' do
        should 'return unauthorized' do
          post :create, {album: {owner_type: 'Group', owner_id: @group.id, name: 'test name'}}, {logged_in_id: @user.id}
          assert_response :unauthorized
        end
      end

      context 'group does not have pictures enabled' do
        setup do
          @group.update_attributes!(pictures: false)
        end

        should 'return unauthorized' do
          post :create, {album: {owner_type: 'Group', owner_id: @group.id, name: 'test name'}}, {logged_in_id: @user.id}
          assert_response :unauthorized
        end
      end

      context 'indicated to remove owner' do
        context 'user is not an admin' do
          should 'still save owner (person) on album' do
            Album.delete_all
            post :create, {album: {name: 'test name'}, remove_owner: true}, {logged_in_id: @user.id}
            assert_equal @user, Album.last.owner
          end
        end

        context 'user is an admin' do
          setup do
            @user.update_attributes(admin: Admin.create!(manage_pictures: true))
          end

          should 'not save owner (person) on album' do
            Album.delete_all
            post :create, {album: {name: 'test name'}, remove_owner: true}, {logged_in_id: @user.id}
            assert_nil Album.last.owner
          end
        end
      end
    end
  end

  context '#update' do
    context 'album is owned by user' do
      setup do
        @album = FactoryGirl.create(:album, owner: @user)
      end

      should 'edit the album' do
        get :edit, {id: @album.id}, {logged_in_id: @user.id}
        assert_response :success
        post :update, {id: @album.id, album: {name: 'test name', description: 'test desc'}}, {logged_in_id: @user.id}
        assert_redirected_to album_path(@album)
        assert_equal 'test name', @album.reload.name
        assert_equal 'test desc', @album.description
      end
    end

    context 'user does not own album' do
      setup do
        @album = FactoryGirl.create(:album)
      end

      should 'return unauthorized' do
        get :edit, {id: @album.id}, {logged_in_id: @user.id}
        assert_response :unauthorized
        post :update, {id: @album.id, album: {name: 'test name', description: 'test desc'}}, {logged_in_id: @user.id}
        assert_response :unauthorized
      end

      context 'user is admin' do
        setup do
          @user.update_attributes(admin: Admin.create!(manage_pictures: true))
        end

        should 'edit the album' do
          get :edit, {id: @album.id}, {logged_in_id: @user.id}
          assert_response :success
          post :update, {id: @album.id, album: {name: 'test name', description: 'test desc'}}, {logged_in_id: @user.id}
          assert_response :redirect
        end
      end
    end
  end

  context '#destroy' do
    context 'album is owned by user' do
      setup do
        @album = FactoryGirl.create(:album, owner: @user)
      end

      should 'delete the album' do
        post :destroy, {id: @album.id}, {logged_in_id: @user.id}
        assert_redirected_to albums_path
        assert_raise(ActiveRecord::RecordNotFound) do
          @album.reload
        end
      end
    end

    context 'user does not own album' do
      setup do
        @album = FactoryGirl.create(:album)
      end

      should 'return unauthorized' do
        post :destroy, {id: @album.id}, {logged_in_id: @user.id}
        assert_response :unauthorized
      end

      context 'user is admin' do
        setup do
          @user.update_attributes(admin: Admin.create!(manage_pictures: true))
        end

        should 'delete the album' do
          post :destroy, {id: @album.id}, {logged_in_id: @user.id}
          assert_response :redirect
        end
      end
    end
  end

end
