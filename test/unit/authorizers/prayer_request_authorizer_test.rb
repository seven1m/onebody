require_relative '../../test_helper'

class PrayerRequestAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @prayer_request = FactoryGirl.create(:prayer_request)
    @group = @prayer_request.group
  end

  should 'not update prayer request' do
    assert_cannot @user, :update, @prayer_request
  end

  should 'not delete prayer request' do
    assert_cannot @user, :delete, @prayer_request
  end

  context 'owned by user' do
    setup do
      @prayer_request.update_attributes!(person: @user)
    end

    should 'update prayer request' do
      assert_can @user, :update, @prayer_request
    end

    should 'delete prayer request' do
      assert_can @user, :delete, @prayer_request
    end
  end

  context 'user is admin with manage_groups privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(manage_groups: true))
    end

    should 'update prayer request' do
      assert_can @user, :update, @prayer_request
    end

    should 'delete prayer request' do
      assert_can @user, :delete, @prayer_request
    end
  end

  context 'user is group member' do
    setup do
      @group.memberships.create(person: @user)
    end

    should 'not update prayer request' do
      assert_cannot @user, :update, @prayer_request
    end

    should 'not delete prayer request' do
      assert_cannot @user, :delete, @prayer_request
    end
  end

  context 'user is group admin' do
    setup do
      @group.memberships.create(person: @user, admin: true)
    end

    should 'update prayer request' do
      assert_can @user, :update, @prayer_request
    end

    should 'delete prayer request' do
      assert_can @user, :delete, @prayer_request
    end
  end

end
