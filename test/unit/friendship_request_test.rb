require_relative '../test_helper'

class FriendshipRequestTest < ActiveSupport::TestCase
  setup do
    @user = FactoryGirl.create(:person)
    @other = FactoryGirl.create(:person)
  end

  should 'work' do
    # no requests and no friendships
    assert @user.can_request_friendship_with?(@other)
    assert !@user.friendship_waiting_on?(@other)
    assert !@user.friendship_rejected_by?(@other)
    assert @other.can_request_friendship_with?(@user)
    assert !@other.friendship_waiting_on?(@user)
    assert !@other.friendship_rejected_by?(@user)

    # new pending request
    @other.friendship_requests.create! from: @user
    assert !@user.can_request_friendship_with?(@other)
    assert @user.friendship_waiting_on?(@other)
    assert !@user.friendship_rejected_by?(@other)
    assert @other.can_request_friendship_with?(@user)
    assert !@other.friendship_waiting_on?(@user)
    assert !@other.friendship_rejected_by?(@user)

    # rejected request
    @other.friendship_requests.find(:first).update_attribute :rejected, true
    assert !@user.can_request_friendship_with?(@other)
    assert !@user.friendship_waiting_on?(@other)
    assert @user.friendship_rejected_by?(@other)
    assert @other.can_request_friendship_with?(@user)
    assert !@other.friendship_waiting_on?(@user)
    assert !@other.friendship_rejected_by?(@user)

    # kill request
    @other.friendship_requests.find(:first).destroy

    # friendship established
    @other.friendships.create! friend: @user
    assert !@user.can_request_friendship_with?(@other)
    assert !@user.friendship_waiting_on?(@other)
    assert !@user.friendship_rejected_by?(@other)
    assert !@other.can_request_friendship_with?(@user)
    assert !@other.friendship_waiting_on?(@user)
    assert !@other.friendship_rejected_by?(@user)
  end
end
