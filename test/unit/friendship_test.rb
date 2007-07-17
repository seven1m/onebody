require File.dirname(__FILE__) + '/../test_helper'

class FriendshipTest < Test::Unit::TestCase
  fixtures :friendships, :people
  
  def test_friendship_creation
    assert_equal 0, people(:jeanette).friends.count
    assert_equal 0, people(:jennie).friends.count
    people(:jeanette).friendships.create :friend => people(:jennie)
    assert_equal 1, people(:jeanette).friends.count
    assert_equal 1, people(:jennie).friends.count
  end
  
  def test_duplicate_friendships_not_allowed
    assert_nothing_raised(ActiveRecord::RecordInvalid) do
      people(:jeanette).friendships.create!(:friend => people(:jennie))
    end
    assert_raise(ActiveRecord::RecordInvalid) do
      people(:jennie).friendships.create!(:friend => people(:jeanette))
    end
  end
  
  def test_friendship_update
    people(:jeanette).friendships.create :friend => people(:jennie)
    f1 = Friendship.find_by_person_id_and_friend_id people(:jeanette).id, people(:jennie).id
    f2 = Friendship.find_by_person_id_and_friend_id people(:jennie).id, people(:jeanette).id
    assert f1.pending
    assert f2.pending
    f1.update_attribute :pending, false
    assert !f1.pending
    assert !f2.reload.pending
  end
  
  def test_friendship_destroy
    Friendship.destroy_all # kill the ones from the fixtures for this test
    people(:jeanette).friendships.create :friend => people(:jennie)
    assert_equal 2, Friendship.count
    people(:jeanette).friendships.find(:first).destroy
  end
end
