require File.dirname(__FILE__) + '/../test_helper'

class FriendshipRequestTest < Test::Unit::TestCase
  fixtures :friendship_requests, :people # no friendship fixtures

  def test_state_methods
    Friendship.delete_all
    
    # no requests and no friendships between tim and jeremy
    assert people(:tim).can_request_friendship_with?(people(:jeremy))
    assert !people(:tim).friendship_waiting_on?(people(:jeremy))
    assert !people(:tim).friendship_rejected_by?(people(:jeremy))
    assert people(:jeremy).can_request_friendship_with?(people(:tim))
    assert !people(:jeremy).friendship_waiting_on?(people(:tim))
    assert !people(:jeremy).friendship_rejected_by?(people(:tim))
    
    # new pending request from tim to jeremy
    people(:jeremy).friendship_requests.create! :from => people(:tim)
    assert !people(:tim).can_request_friendship_with?(people(:jeremy))
    assert people(:tim).friendship_waiting_on?(people(:jeremy))
    assert !people(:tim).friendship_rejected_by?(people(:jeremy))
    assert people(:jeremy).can_request_friendship_with?(people(:tim))
    assert !people(:jeremy).friendship_waiting_on?(people(:tim))
    assert !people(:jeremy).friendship_rejected_by?(people(:tim))
    
    # rejected request from tim to jeremy
    people(:jeremy).friendship_requests.find(:first).update_attribute :rejected, true
    assert !people(:tim).can_request_friendship_with?(people(:jeremy))
    assert !people(:tim).friendship_waiting_on?(people(:jeremy))
    assert people(:tim).friendship_rejected_by?(people(:jeremy))
    assert people(:jeremy).can_request_friendship_with?(people(:tim))
    assert !people(:jeremy).friendship_waiting_on?(people(:tim))
    assert !people(:jeremy).friendship_rejected_by?(people(:tim))
    
    # kill request
    people(:jeremy).friendship_requests.find(:first).destroy
    
    # friendship established between tim and jeremy
    people(:jeremy).friendships.create! :friend => people(:tim)
    assert !people(:tim).can_request_friendship_with?(people(:jeremy))
    assert !people(:tim).friendship_waiting_on?(people(:jeremy))
    assert !people(:tim).friendship_rejected_by?(people(:jeremy))
    assert !people(:jeremy).can_request_friendship_with?(people(:tim))
    assert !people(:jeremy).friendship_waiting_on?(people(:tim))
    assert !people(:jeremy).friendship_rejected_by?(people(:tim))
  end
end
