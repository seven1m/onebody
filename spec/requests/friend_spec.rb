require_relative '../rails_helper'

describe 'Friend', type: :request do
  before do
    Setting.set(1, 'Features', 'Friends', true)
    @user = FactoryGirl.create(:person)
    @friend = FactoryGirl.create(:person)
    @stranger = FactoryGirl.create(:person)
    Friendship.create!(person: @user, friend: @friend)
  end

  it 'has proper links' do
    sign_in_as @user

    view_profile @friend
    assert_select 'body', html: /Add to Friends/, count: 0
    assert_select '#add_friend_' + @friend.id.to_s, count: 0

    view_profile @stranger
    assert_select 'body', html: /Add to Friends/
    assert_select '#add_friend_' + @stranger.id.to_s

    post "/people/#{@user.id}/friends?friend_id=#{@stranger.id}"
    expect(response).to be_success
    assert_select 'body', html: /friend request has been sent/

    view_profile @stranger
    assert_select '#add_friend_' + @stranger.id.to_s + '.disabled'
    assert_select '.add-friend', html: /pending/

    sign_in_as @stranger
    assert_select '.friends-alert', html: /pending friend requests/
    f = @stranger.friendship_requests.where(from_id: @user.id).first

    put "/people/#{@stranger.id}/friends/#{f.id}?accept=true"
    expect(response).to be_redirect
    view_profile @user
    assert_select 'body', html: /Add to Friends/, count: 0
    assert_select '#add_friend_' + @user.id.to_s, count: 0
  end
end
