require_relative '../rails_helper'

describe FriendshipRequest, type: :model do
  before do
    @user = FactoryGirl.create(:person, email: 'user@example.com')
    @other = FactoryGirl.create(:person, email: 'other@example.com')
  end

  context 'when both have no requests and no friendships' do
    it 'should be able to request friendship with other' do
      expect(@user.can_request_friendship_with?(@other)).to be true
    end

    it 'should not be waiting on the other' do
      expect(@user.friendship_waiting_on?(@other)).not_to be true
    end

    it 'should not be rejected by the other' do
      expect(@user.friendship_rejected_by?(@other)).not_to be true
    end

    it 'should be able to request friendship with the other' do
      expect(@other.can_request_friendship_with?(@user)).to be true
    end

    it 'should not be waiting on the other' do
      expect(@other.friendship_waiting_on?(@user)).not_to be true
    end

    it 'should not reject the other' do
      expect(@other.friendship_rejected_by?(@user)).not_to be true
    end
  end

  context 'new pending request' do
    before { @other.friendship_requests.create! from: @user }

    it 'should be able to request friendship with the other' do
      expect(@user.can_request_friendship_with?(@other)).not_to be true
    end

    it 'should work' do
      expect(@user.friendship_waiting_on?(@other)).to be true
      expect(@user.friendship_rejected_by?(@other)).not_to be true
      expect(@other.can_request_friendship_with?(@user)).to be true
      expect(@other.friendship_waiting_on?(@user)).not_to be true
      expect(@other.friendship_rejected_by?(@user)).not_to be true
    end
  end

  context 'rejected request' do
    before do
      @other.friendship_requests.create! from: @user
      @other.friendship_requests.first.update_attribute :rejected, true
    end

    it 'should work' do
      expect(@user.can_request_friendship_with?(@other)).not_to be true
      expect(@user.friendship_waiting_on?(@other)).not_to be true
      expect(@user.friendship_rejected_by?(@other)).to be true
      expect(@other.can_request_friendship_with?(@user)).to be true
      expect(@other.friendship_waiting_on?(@user)).not_to be true
      expect(@other.friendship_rejected_by?(@user)).not_to be true
    end
  end
  context 'friendship established' do
    before { @other.friendships.create! friend: @user }
    it 'should work' do
      expect(@user.can_request_friendship_with?(@other)).not_to be true
      expect(@user.friendship_waiting_on?(@other)).not_to be true
      expect(@user.friendship_rejected_by?(@other)).not_to be true
      expect(@other.can_request_friendship_with?(@user)).not_to be true
      expect(@other.friendship_waiting_on?(@user)).not_to be true
      expect(@other.friendship_rejected_by?(@user)).not_to be true
    end
  end

  context '#person' do
    before do
      @other.friendship_requests.create! from: @user
      @friendship_request = @other.friendship_requests.first
    end

    context 'is empty' do
      it 'should be invalid' do
        @friendship_request.person = nil
        expect(@friendship_request).to be_invalid
      end
    end
  end

  context '#from' do
    before do
      @other.friendship_requests.create! from: @user
      @friendship_request = @other.friendship_requests.first
    end

    context 'is empty' do
      it 'should be invalid' do
        @friendship_request.from = nil
        expect(@friendship_request).to be_invalid
      end
    end
  end
end
