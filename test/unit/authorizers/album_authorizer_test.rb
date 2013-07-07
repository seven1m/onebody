require_relative '../../test_helper'

class AlbumAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @album = FactoryGirl.create(:album)
  end

  should 'not read album' do
    assert_cannot @user, :read, @album
  end

  should 'not update album' do
    assert_cannot @user, :update, @album
  end

  should 'not delete album' do
    assert_cannot @user, :delete, @album
  end

  context 'new album' do
    setup do
      @album = Album.new
    end

    should 'create album' do
      assert_can @user, :create, @album
    end

    context 'belonging to a group' do
      setup do
        @group = FactoryGirl.create(:group)
        @album.owner = @group
      end

      should 'not create album' do
        assert_cannot @user, :create, @album
      end

      context 'user is group member' do
        setup do
          @group.memberships.create!(person: @user)
        end

        should 'create album' do
          assert_can @user, :create, @album
        end

        context 'group has pictures disabled' do
          setup do
            @group.update_attributes!(pictures: false)
          end

          should 'not create album' do
            assert_cannot  @user, :create, @album
          end
        end
      end

      context 'user is admin with manage_pictures and manage_groups privileges' do
        setup do
          @user.update_attributes!(admin: Admin.create(manage_pictures: true, manage_groups: true))
        end

        should 'create album' do
          assert_can @user, :create, @album
        end

        context 'group has pictures disabled' do
          setup do
            @group.update_attributes!(pictures: false)
          end

          should 'not create album' do
            assert_cannot  @user, :create, @album
          end
        end
      end
    end
  end

  context 'album is marked public' do
    setup do
      @album.update_attributes!(is_public: true)
    end

    should 'read album' do
      assert_can @user, :read, @album
    end

    should 'list album' do
      assert_include AlbumAuthorizer.readable_by(@user), @album
    end
  end

  context 'owned by user' do
    setup do
      @album.update_attributes!(owner: @user)
    end

    should 'read album' do
      assert_can @user, :read, @album
    end

    should 'update album' do
      assert_can @user, :update, @album
    end

    should 'delete album' do
      assert_can @user, :delete, @album
    end

    should 'list album' do
      assert_include AlbumAuthorizer.readable_by(@user), @album
    end
  end

  context 'owned by a friend' do
    setup do
      @friend = FactoryGirl.create(:person)
      Friendship.create!(person: @user, friend: @friend)
      @album.update_attributes!(owner: @friend)
    end

    should 'read album' do
      assert_can @user, :read, @album
    end

    should 'list album' do
      assert_include AlbumAuthorizer.readable_by(@user), @album
    end
  end

  context 'album in a group' do
    setup do
      @group = FactoryGirl.create(:group)
      @album.update_attributes!(owner: @group)
    end

    should 'not read album' do
      assert_cannot @user, :read, @album
    end

    should 'not update album' do
      assert_cannot @user, :update, @album
    end

    should 'not delete album' do
      assert_cannot @user, :delete, @album
    end

    should 'not list album' do
      assert_not_include AlbumAuthorizer.readable_by(@user), @album
    end

    context 'user is group member' do
      setup do
        @group.memberships.create(person: @user)
      end

      should 'read album' do
        assert_can @user, :read, @album
      end

      should 'list album' do
        assert_include AlbumAuthorizer.readable_by(@user), @album
      end

      should 'not update album' do
        assert_cannot  @user, :update, @album
      end

      should 'not delete album' do
        assert_cannot  @user, :delete, @album
      end
    end

    context 'user is group admin' do
      setup do
        @group.memberships.create(person: @user, admin: true)
      end

      should 'read album' do
        assert_can @user, :read, @album
      end

      should 'list album' do
        assert_include AlbumAuthorizer.readable_by(@user), @album
      end

      should 'update album' do
        assert_can @user, :update, @album
      end

      should 'delete album' do
        assert_can @user, :delete, @album
      end
    end
  end

  context 'user is admin with manage_pictures privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(manage_pictures: true))
    end

    should 'read album' do
      assert_can @user, :read, @album
    end

    should 'list album' do
      assert_include AlbumAuthorizer.readable_by(@user), @album
    end

    should 'update album' do
      assert_can @user, :update, @album
    end

    should 'delete album' do
      assert_can @user, :delete, @album
    end
  end
end
