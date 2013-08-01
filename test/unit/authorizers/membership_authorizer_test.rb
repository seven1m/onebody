require_relative '../../test_helper'

class MembershipAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group)
    @membership = @group.memberships.create!
  end

  should 'not update membership' do
    assert_cannot @user, :update, @membership
  end

  should 'not delete membership' do
    assert_cannot @user, :delete, @membership
  end

  context 'owned by user' do
    setup do
      @membership.update_attributes!(person: @user)
    end

    should 'update membership' do
      assert_can @user, :update, @membership
    end

    should 'delete membership' do
      assert_can @user, :delete, @membership
    end
  end

  context 'user is admin with manage_groups privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(manage_groups: true))
    end

    should 'update membership' do
      assert_can @user, :update, @membership
    end

    should 'delete membership' do
      assert_can @user, :delete, @membership
    end
  end

  context 'user is admin with edit_profiles privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(edit_profiles: true))
    end

    should 'update membership' do
      assert_can @user, :update, @membership
    end

    should 'delete membership' do
      assert_can @user, :delete, @membership
    end
  end

  context 'user is group admin' do
    setup do
      @group.memberships.create(person: @user, admin: true)
    end

    should 'update membership' do
      assert_can @user, :update, @membership
    end

    should 'delete membership' do
      assert_can @user, :delete, @membership
    end
  end

  context 'user is family member' do
    setup do
      @spouse = FactoryGirl.create(:person, family: @user.family)
      @membership.update_attributes!(person: @spouse)
    end

    should 'update membership' do
      assert_can @user, :update, @membership
    end

    should 'delete membership' do
      assert_can @user, :delete, @membership
    end

    context 'user is child' do
      setup do
        @user.update_attributes!(child: true)
      end

      should 'not update membership' do
        assert_cannot @user, :update, @membership
      end

      should 'not delete membership' do
        assert_cannot @user, :delete, @membership
      end
    end
  end

end
