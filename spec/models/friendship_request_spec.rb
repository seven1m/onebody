require_relative '../rails_helper'

describe FriendshipRequest do
  before do
    @user = FactoryGirl.create(:person)
    @other = FactoryGirl.create(:person)
  end

  it 'should work' do
    # no requests and no friendships
    expect(@user.can_request_friendship_with?(@other)).to be
    expect(@user.friendship_waiting_on?(@other)).not_to be
    expect(@user.friendship_rejected_by?(@other)).not_to be
    expect(@other.can_request_friendship_with?(@user)).to be
    expect(@other.friendship_waiting_on?(@user)).not_to be
    expect(@other.friendship_rejected_by?(@user)).not_to be

    # new pending request
    @other.friendship_requests.create! from: @user
    expect(@user.can_request_friendship_with?(@other)).not_to be
    expect(@user.friendship_waiting_on?(@other)).to be
    expect(@user.friendship_rejected_by?(@other)).not_to be
    expect(@other.can_request_friendship_with?(@user)).to be
    expect(@other.friendship_waiting_on?(@user)).not_to be
    expect(@other.friendship_rejected_by?(@user)).not_to be

    # rejected request
    @other.friendship_requests.first.update_attribute :rejected, true
    expect(@user.can_request_friendship_with?(@other)).not_to be
    expect(@user.friendship_waiting_on?(@other)).not_to be
    expect(@user.friendship_rejected_by?(@other)).to be
    expect(@other.can_request_friendship_with?(@user)).to be
    expect(@other.friendship_waiting_on?(@user)).not_to be
    expect(@other.friendship_rejected_by?(@user)).not_to be

    # kill request
    @other.friendship_requests.first.destroy

    # friendship established
    @other.friendships.create! friend: @user
    expect(@user.can_request_friendship_with?(@other)).not_to be
    expect(@user.friendship_waiting_on?(@other)).not_to be
    expect(@user.friendship_rejected_by?(@other)).not_to be
    expect(@other.can_request_friendship_with?(@user)).not_to be
    expect(@other.friendship_waiting_on?(@user)).not_to be
    expect(@other.friendship_rejected_by?(@user)).not_to be
  end
end
