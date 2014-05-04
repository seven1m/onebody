require_relative '../test_helper'

class FriendshipTest < ActiveSupport::TestCase
  def setup
    Setting.set(1, 'Features', 'Friends', true)
    @user = FactoryGirl.create(:person)
    @other = FactoryGirl.create(:person)
  end

  should 'make friends' do
    assert_equal 0, @user.friends.count
    assert_equal 0, @other.friends.count
    @user.friendships.create friend: @other
    assert_equal 1, @user.friends.count
    assert_equal 1, @other.friends.count
  end

  should 'not allow duplicate friendships' do
    assert_nothing_raised(ActiveRecord::RecordInvalid) do
      @user.friendships.create! friend: @other
    end
    assert_raise(ActiveRecord::RecordInvalid) do
      @other.friendships.create! friend: @user
    end
  end

  should 'destroy friendships' do
    @user.friendships.create! friend: @other
    assert_equal 2, Friendship.count
    @user.friendships.first.destroy
    assert_equal 0, Friendship.count
  end
end
