require 'rails_helper'

describe Friendship, type: :model do
  before do
    Setting.set(1, 'Features', 'Friends', true)
    @user = FactoryGirl.create(:person)
    @other = FactoryGirl.create(:person)
  end

  it 'should make friends' do
    expect(@user.friends.count).to eq(0)
    expect(@other.friends.count).to eq(0)
    @user.friendships.create friend: @other
    expect(@user.friends.count).to eq(1)
    expect(@other.friends.count).to eq(1)
  end

  it 'should not allow duplicate friendships' do
    expect { @user.friendships.create! friend: @other }.to_not raise_error
    expect { @other.friendships.create! friend: @user }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'should destroy friendships' do
    @user.friendships.create! friend: @other
    expect(Friendship.count).to eq(2)
    @user.friendships.first.destroy
    expect(Friendship.count).to eq(0)
  end

  context 'when #person is nil' do
    before do
      @user.friendships.create friend: @other
      @friendship = @user.friendships.first
      @friendship.person = nil
    end

    it 'should be invalid' do
      expect(@friendship).to be_invalid
    end
  end

  context 'when #friend is nil' do
    before do
      @user.friendships.create friend: @other
      @friendship = @user.friendships.first
      @friendship.friend = nil
    end

    it 'should be invalid' do
      expect(@friendship).to be_invalid
    end
  end
end
