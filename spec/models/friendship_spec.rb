require_relative '../spec_helper'

describe Friendship do
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
    assert_nothing_raised(ActiveRecord::RecordInvalid) do
      @user.friendships.create! friend: @other
    end
    assert_raise(ActiveRecord::RecordInvalid) do
      @other.friendships.create! friend: @user
    end
  end

  it 'should destroy friendships' do
    @user.friendships.create! friend: @other
    expect(Friendship.count).to eq(2)
    @user.friendships.first.destroy
    expect(Friendship.count).to eq(0)
  end
end
