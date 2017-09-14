require 'rails_helper'

describe FriendsController, type: :controller do
  before do
    @person, @friend, @other_person = FactoryGirl.create_list(:person, 3)
    @friendship = @person.friendships.create(friend: @friend)
  end

  it 'should list all friends' do
    # self
    get :index,
        params: { person_id: @person.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    expect(assigns(:friendships).length).to eq(1)
    # friend
    get :index,
        params: { person_id: @person.id },
        session: { logged_in_id: @friend.id }
    expect(response).to be_success
    expect(assigns(:friendships).length).to eq(1)
    # someone else
    get :index,
        params: { person_id: @person.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_success
    expect(assigns(:friendships).length).to eq(1)
  end

  it 'should not show friends if user cannot see the person' do
    @person.update_attribute(:visible, false)
    get :index,
        params: { person_id: @person.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_missing
  end

  it 'should not show friends that the user cannot see' do
    @friend.update_attribute(:visible, false)
    get :index,
        params: { person_id: @person.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_success
    expect(assigns(:friendships).length).to eq(0)
  end

  it 'should list pending friendships' do
    @pending = @person.friendship_requests.create(from: @other_person)
    get :index,
        params: { person_id: @person.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    expect(assigns(:pending).length).to eq(1)
  end

  it 'should not list pending friendships for anyone but the user' do
    @pending = @person.friendship_requests.create(from: @other_person)
    get :index,
        params: { person_id: @person.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_success
    expect(assigns(:pending).length).to eq(0)
  end

  it 'should create a friendship request' do
    req_count = FriendshipRequest.count
    post :create,
         params: { person_id: @person.id, friend_id: @other_person.id },
         session: { logged_in_id: @person.id }
    expect(response).to be_success
    expect(FriendshipRequest.count).to eq(req_count + 1)
  end

  it 'should accept a friendship request' do
    friendship_count = Friendship.count
    @req = @person.friendship_requests.create!(from: @other_person)
    post :update,
         params: { person_id: @person.id, id: @req.id, accept: true },
         session: { logged_in_id: @person.id }
    expect(response).to redirect_to(person_friends_path(@person))
    expect { @req.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(Friendship.count).to eq(friendship_count + 2)
  end

  it 'should reject a friendship request' do
    friendship_count = Friendship.count
    @req = @person.friendship_requests.create!(from: @other_person)
    post :update,
         params: { person_id: @person.id, id: @req.id, reject: true },
         session: { logged_in_id: @person.id }
    expect(response).to redirect_to(person_friends_path(@person))
    expect(@req.reload.rejected).to be
    expect(Friendship.count).to eq(friendship_count)
  end

  it 'should delete a friendship' do
    friendship_count = Friendship.count
    post :destroy,
         params: { person_id: @person.id, id: @friendship.friend.id },
         session: { logged_in_id: @person.id }
    expect(response).to redirect_to(person_friends_path(@person))
    expect { @friendship.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(Friendship.count).to eq(friendship_count - 2)
  end

  it 'should reorder friends' do
    @other_friendship = @person.friendships.create(friend: @other_person)
    post :reorder,
         params: { person_id: @person.id, friends: [@friendship.id, @other_friendship.id] },
         session: { logged_in_id: @person.id }
    expect(@friendship.reload.ordering).to eq(0)
    expect(@other_friendship.reload.ordering).to eq(1)
    post :reorder,
         params: { person_id: @person.id, friends: [@other_friendship.id, @friendship.id] },
         session: { logged_in_id: @person.id }
    expect(@other_friendship.reload.ordering).to eq(0)
    expect(@friendship.reload.ordering).to eq(1)
  end
end
