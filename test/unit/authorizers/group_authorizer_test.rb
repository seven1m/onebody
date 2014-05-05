require_relative '../../test_helper'

class GroupAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group)
  end

  should 'read group' do
    assert_can @user, :read, @group
  end

  should 'not update group' do
    assert_cannot @user, :update, @group
  end

  should 'not delete group' do
    assert_cannot @user, :delete, @group
  end

  context 'group is hidden' do
    setup do
      @group.update_attributes!(hidden: true)
    end

    should 'not read group' do
      assert_cannot @user, :read, @group
    end

    context 'user is a group member' do
      setup do
        @group.memberships.create!(person: @user)
      end

      should 'read group' do
        assert_can @user, :read, @group
      end
    end
  end

  context 'group is private' do
    setup do
      @group.update_attributes!(private: true)
    end

    should 'not read group' do
      assert_cannot @user, :read, @group
    end

    context 'user is a group member' do
      setup do
        @group.memberships.create!(person: @user)
      end

      should 'read group' do
        assert_can @user, :read, @group
      end
    end
  end

  context 'user is a group member' do
    setup do
      @group.memberships.create(person: @user)
    end

    should 'read group' do
      assert_can @user, :read, @group
    end

    should 'not update group' do
      assert_cannot @user, :update, @group
    end

    should 'not delete group' do
      assert_cannot @user, :delete, @group
    end
  end

  context 'user is a group admin' do
    setup do
      @group.memberships.create(person: @user, admin: true)
    end

    should 'update group' do
      assert_can @user, :update, @group
    end

    should 'delete group' do
      assert_can @user, :delete, @group
    end
  end

  context 'user is an admin with manage_groups privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(manage_groups: true))
    end

    should 'read group' do
      assert_can @user, :read, @group
    end

    should 'update group' do
      assert_can @user, :update, @group
    end

    should 'delete group' do
      assert_can @user, :delete, @group
    end
  end

end
