require_relative '../test_helper'

class AbilityTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
  end

  context 'person' do
    should 'not update a stranger' do
      @stranger = FactoryGirl.create(:person)
      assert_cannot @user, :update, @stranger
    end

    should 'update self' do
      assert_can @user, :update, @user
    end

    should 'update spouse' do
      @spouse = FactoryGirl.create(:person, family: @user.family, child: false)
      assert_can @user, :update, @spouse
    end

    should 'update child in family' do
      @child = FactoryGirl.create(:person, family: @user.family, child: true)
      assert_can @user, :update, @child
    end

    should 'not update deleted person in family' do
      @deleted = FactoryGirl.create(:person, family: @user.family, deleted: true)
      assert_cannot @user, :update, @deleted
    end

    context 'user is not an adult' do
      setup do
        @user.update_attributes!(child: true)
      end

      should 'not update others in family' do
        @adult = FactoryGirl.create(:person, family: @user.family, child: false)
        assert_cannot @user, :update, @adult
        @child = FactoryGirl.create(:person, family: @user.family, child: true)
        assert_cannot @user, :update, @child
      end
    end

    context 'user is admin with edit_profiles privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(edit_profiles: true))
      end

      should 'update a stranger' do
        @stranger = FactoryGirl.create(:person)
        assert_can @user, :update, @stranger
      end

      should 'update a deleted person' do
        @stranger = FactoryGirl.create(:person, deleted: true)
        assert_can @user, :update, @stranger
      end

      should 'destroy stranger' do
        @stranger = FactoryGirl.create(:person)
        assert_can @user, :destroy, @stranger
      end

      should 'create new person' do
        assert_can @user, :create, Person
      end
    end

    should 'not destroy self' do
      assert_cannot @user, :destroy, @user
    end

    should 'not destroy spouse' do
      @spouse = FactoryGirl.create(:person, family: @user.family, child: false)
      assert_cannot @user, :destroy, @spouse
    end

    should 'not create new person' do
      assert_cannot @user, :create, Person
    end
  end

  context 'family' do
    should 'update own family' do
      assert_can @user, :update, @user.family
    end

    should 'not update a stranger family' do
      @stranger = FactoryGirl.create(:person)
      assert_cannot @user, :update, @stranger.family
    end

    should 'not update deleted family' do
      @deleted = FactoryGirl.create(:family, deleted: true)
      assert_cannot @user, :update, @deleted
    end

    context 'user is not an adult' do
      setup do
        @user.update_attributes!(child: true)
      end

      should 'not update family' do
        assert_cannot @user, :update, @user.family
      end
    end

    context 'user is admin with edit_profiles privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(edit_profiles: true))
      end

      should 'update a stranger family' do
        @stranger = FactoryGirl.create(:person)
        assert_can @user, :update, @stranger.family
      end

      should 'update a deleted person' do
        @deleted = FactoryGirl.create(:family, deleted: true)
        assert_can @user, :update, @deleted
      end

      should 'destroy stranger' do
        @stranger = FactoryGirl.create(:person)
        assert_can @user, :destroy, @stranger.family
      end

      should 'create new family' do
        assert_can @user, :create, Family
      end
    end

    should 'not destroy self' do
      assert_cannot @user, :destroy, @user.family
    end

    should 'not create new family' do
      assert_cannot @user, :create, Family
    end
  end

  context 'group' do
    setup do
      @group = FactoryGirl.create(:group)
    end

    should 'not update group' do
      assert_cannot @user, :update, @group
    end

    should 'not destroy group' do
      assert_cannot @user, :destroy, @group
    end

    context 'user is a group member' do
      setup do
        @group.memberships.create(person: @user)
      end

      should 'not update group' do
        assert_cannot @user, :update, @group
      end

      should 'not destroy group' do
        assert_cannot @user, :destroy, @group
      end
    end

    context 'user is a group admin' do
      setup do
        @group.memberships.create(person: @user, admin: true)
      end

      should 'update group' do
        assert_can @user, :update, @group
      end

      should 'destroy group' do
        assert_can @user, :destroy, @group
      end
    end

    context 'user is an admin with manage_groups privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_groups: true))
      end

      should 'update group' do
        assert_can @user, :update, @group
      end

      should 'destroy group' do
        assert_can @user, :destroy, @group
      end
    end
  end

  context 'album' do
    setup do
      @album = FactoryGirl.create(:album)
    end

    should 'not update album' do
      assert_cannot @user, :update, @album
    end

    should 'not destroy album' do
      assert_cannot @user, :destroy, @album
    end

    context 'owned by user' do
      setup do
        @album.update_attributes!(person: @user)
      end

      should 'update album' do
        assert_can @user, :update, @album
      end

      should 'destroy album' do
        assert_can @user, :destroy, @album
      end
    end

    context 'admin with manage_pictures privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_pictures: true))
      end

      should 'update album' do
        assert_can @user, :update, @album
      end

      should 'destroy album' do
        assert_can @user, :destroy, @album
      end
    end
  end
end
