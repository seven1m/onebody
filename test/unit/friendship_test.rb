require File.dirname(__FILE__) + '/../test_helper'

class FriendshipTest < ActiveSupport::TestCase
  fixtures :friendships, :people
  
  def setup
    Setting.set(1, 'Features', 'Friends', true)
  end
  
  def test_friendship_creation
    Friendship.destroy_all # kill the ones from the fixtures for this test
    assert_equal 0, people(:jane).friends.count
    assert_equal 0, people(:jennie).friends.count
    people(:jane).friendships.create :friend => people(:jennie)
    assert_equal 1, people(:jane).friends.count
    assert_equal 1, people(:jennie).friends.count
  end
  
  def test_duplicate_friendships_not_allowed
    Friendship.destroy_all # kill the ones from the fixtures for this test
    assert_nothing_raised(ActiveRecord::RecordInvalid) do
      people(:jane).friendships.create! :friend => people(:jennie)
    end
    assert_raise(ActiveRecord::RecordInvalid) do
      people(:jennie).friendships.create! :friend => people(:jane)
    end
  end
  
  def test_friendship_destroy
    Friendship.destroy_all # kill the ones from the fixtures for this test
    people(:jane).friendships.create! :friend => people(:jennie)
    assert_equal 2, Friendship.count
    people(:jane).friendships.find(:first).destroy
    assert_equal 0, Friendship.count
  end
end
