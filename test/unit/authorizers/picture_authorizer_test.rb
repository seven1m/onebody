require_relative '../../test_helper'

class PictureAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @picture = FactoryGirl.create(:picture)
  end

  should 'not update picture' do
    assert_cannot @user, :update, @picture
  end

  should 'not delete picture' do
    assert_cannot @user, :delete, @picture
  end

  context 'owned by user' do
    setup do
      @picture.update_attributes!(person: @user)
    end

    should 'update picture' do
      assert_can @user, :update, @picture
    end

    should 'delete picture' do
      assert_can @user, :delete, @picture
    end
  end

  context 'picture in album in group' do
    setup do
      @group = FactoryGirl.create(:group)
      @picture.album.update_attributes!(owner: @group)
    end

    context 'user is group member' do
      setup do
        @group.memberships.create(person: @user)
      end

      should 'create picture in album' do
        assert_can @user, :create, @picture.album.pictures.new
      end

      should 'not update picture' do
        assert_cannot @user, :update, @picture
      end

      should 'not delete picture' do
        assert_cannot @user, :delete, @picture
      end

      context 'group does not allow pictures' do
        setup do
          @group.update_attributes!(pictures: false)
        end

        should 'create picture in album' do
          assert_cannot @user, :create, @picture.album.pictures.new
        end
      end
    end

    context 'user is group admin' do
      setup do
        @group.memberships.create(person: @user, admin: true)
      end

      should 'update picture' do
        assert_can @user, :update, @picture
      end

      should 'delete picture' do
        assert_can @user, :delete, @picture
      end
    end
  end

  context 'user is admin with manage_pictures privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(manage_pictures: true))
    end

    should 'update picture' do
      assert_can @user, :update, @picture
    end

    should 'delete picture' do
      assert_can @user, :delete, @picture
    end
  end

end
