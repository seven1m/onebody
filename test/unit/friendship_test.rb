require File.dirname(__FILE__) + '/../test_helper'

class FriendshipTest < Test::Unit::TestCase
  fixtures :friendships, :people
  
  def test_friendship_creation
    Friendship.destroy_all # kill the ones from the fixtures for this test
    assert_equal 0, people(:jeanette).all_friendships.count
    assert_equal 0, people(:jennie).all_friendships.count
    people(:jeanette).friendships.create :friend => people(:jennie), :initiated_by => people(:jeanette)
    assert_equal 1, people(:jeanette).all_friendships.count
    assert_equal 1, people(:jennie).all_friendships.count
    assert people(:jeanette).pending_friend?(people(:jennie))
  end
  
  def test_duplicate_friendships_not_allowed
    Friendship.destroy_all # kill the ones from the fixtures for this test
    assert_nothing_raised(ActiveRecord::RecordInvalid) do
      people(:jeanette).friendships.create!(:friend => people(:jennie), :initiated_by => people(:jeanette))
    end
    assert_raise(ActiveRecord::RecordInvalid) do
      people(:jennie).friendships.create!(:friend => people(:jeanette), :initiated_by => people(:jeanette))
    end
  end
  
  def test_friendship_update
    people(:jeanette).friendships.create :friend => people(:jennie), :initiated_by => people(:jeanette)
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
    assert_nothing_raised do
      people(:jeanette).friendships.create! :friend => people(:jennie), :initiated_by => people(:jeanette)
    end
    assert_equal 2, Friendship.count
    people(:jeanette).all_friendships.find(:first).destroy
  end
  
  def test_can_request_friendship
    assert people(:jeanette).can_request_friendship?(people(:jennie))
    assert people(:jennie).can_request_friendship?(people(:jeanette))
    f = nil
    assert_nothing_raised do
      f = people(:jeanette).friendships.create(:friend => people(:jennie), :initiated_by => people(:jeanette))
    end
    assert !people(:jeanette).can_request_friendship?(people(:jennie))
    assert people(:jennie).can_request_friendship?(people(:jeanette))
    assert_nothing_raised do
      f.update_attributes! :rejected => true, :rejected_by => people(:jennie)
    end
    assert people(:jennie).rejected_friendship? people(:jeanette)
    assert !people(:jeanette).can_request_friendship?(people(:jennie))
    assert people(:jennie).rejected_friendship?(people(:jeanette))
    assert people(:jennie).can_request_friendship?(people(:jeanette))
  end
  
  def test_requested_to
    assert_equal people(:jeremy), people(:tim).friendships.find_by_friend_id(people(:jeremy)).requested_to
    assert_equal people(:tim), people(:tim).friendships.find_by_friend_id(people(:jennie)).requested_to
  end
end
