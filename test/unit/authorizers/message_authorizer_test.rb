require_relative '../../test_helper'

class MessageAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @message = FactoryGirl.create(:message)
  end

  should 'not update message' do
    assert_cannot @user, :update, @message
  end

  should 'not delete message' do
    assert_cannot @user, :delete, @message
  end

  context 'owned by user' do
    setup do
      @message.update_attributes!(person: @user)
    end

    should 'update message' do
      assert_can @user, :update, @message
    end

    should 'delete message' do
      assert_can @user, :delete, @message
    end
  end

  context 'message is not in a group' do
    context 'user is admin with manage_groups privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_groups: true))
      end

      should 'not update message' do
        assert_cannot @user, :update, @message
      end

      should 'not delete message' do
        assert_cannot @user, :delete, @message
      end
    end
  end

  context 'message in a group' do
    setup do
      @group = FactoryGirl.create(:group)
      @message.update_attributes!(group: @group)
    end

    should 'not update message' do
      assert_cannot @user, :update, @message
    end

    should 'not delete message' do
      assert_cannot @user, :delete, @message
    end

    context 'user is admin with manage_groups privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_groups: true))
      end

      should 'update message' do
        assert_can @user, :update, @message
      end

      should 'delete message' do
        assert_can @user, :delete, @message
      end
    end

    context 'user is group admin' do
      setup do
        @group.memberships.create(person: @user, admin: true)
      end

      should 'update message' do
        assert_can @user, :update, @message
      end

      should 'delete message' do
        assert_can @user, :delete, @message
      end
    end
  end

end
