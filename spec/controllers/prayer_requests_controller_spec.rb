require 'rails_helper'

describe PrayerRequestsController, type: :controller do
  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group = FactoryGirl.create(:group)
    @group.memberships.create(person_id: @person.id)
    @prayer_request = FactoryGirl.create(:prayer_request, group: @group, person: @person)
  end

  it 'should list all prayer requests' do
    get :index,
        params: { group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    expect(assigns(:reqs).length).to eq(1)
  end

  it 'should list all answered prayer requests' do
    @unanswered = FactoryGirl.create(:prayer_request, group: @group, answer: nil, person: @person)
    get :index,
        params: { answered: true, group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    expect(assigns(:reqs).length).to eq(1)
  end

  it 'should show a prayer request' do
    get :show,
        params: { id: @prayer_request.id, group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
  end

  it 'should not show a prayer request if the user is not a member of the group' do
    get :show,
        params: { id: @prayer_request.id, group_id: @group.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_forbidden
  end

  it 'should create a prayer request' do
    get :new,
        params: { group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    post :create,
         params: { group_id: @group.id, prayer_request: { person_id: @person.id, request: 'test req', answer: 'test answer', answered_at: '1/1/2010' } },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    new_req = PrayerRequest.last
    expect(new_req.request).to eq('test req')
    expect(new_req.answer).to eq('test answer')
    expect(new_req.answered_at.strftime('%m/%d/%Y')).to eq('01/01/2010')
    expect(ActionMailer::Base.deliveries.last).to be_nil
  end

  it 'should create a prayer request and send email to group members' do
    @group.memberships.create(person_id: @other_person.id)
    get :new,
        params: { group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    post :create,
         params: { group_id: @group.id, send_email: 1, prayer_request: { person_id: @person.id, request: 'test req', answer: 'test answer', answered_at: '1/1/2010' } },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    new_req = PrayerRequest.last
    expect(new_req.request).to eq('test req')
    expect(new_req.answer).to eq('test answer')
    expect(new_req.answered_at.strftime('%m/%d/%Y')).to eq('01/01/2010')
    expect(ActionMailer::Base.deliveries.last.subject).to match(/Prayer Request in Small Group/)
  end

  it 'should not create a prayer request if the user is not a member of the group' do
    get :new,
        params: { group_id: @group.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_forbidden
    post :create,
         params: { group_id: @group.id, prayer_request: { request: 'test req', answer: 'test answer', answered_at: '1/1/2010' } },
         session: { logged_in_id: @other_person.id }
    expect(response).to be_forbidden
  end

  it 'should edit a prayer request' do
    get :edit,
        params: { id: @prayer_request.id, group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    post :update,
         params: { id: @prayer_request.id, group_id: @group.id, prayer_request: { request: 'test req', answer: 'test answer', answered_at: '2010-01-01' } },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    expect(@prayer_request.reload.request).to eq('test req')
    expect(@prayer_request.answer).to eq('test answer')
    expect(@prayer_request.answered_at.strftime('%m/%d/%Y')).to eq('01/01/2010')
  end

  it 'should not edit a prayer request if the user is not a member of the group' do
    get :edit,
        params: { id: @prayer_request.id, group_id: @group.id },
        session: { logged_in_id: @other_person.id }
    expect(response).to be_forbidden
    post :update,
         params: { id: @prayer_request.id, group_id: @group.id, prayer_request: { request: 'test req', answer: 'test answer', answered_at: '1/1/2010' } },
         session: { logged_in_id: @other_person.id }
    expect(response).to be_forbidden
  end

  it 'should delete a prayer request' do
    post :destroy,
         params: { id: @prayer_request.id, group_id: @group.id },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    expect { @prayer_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should not delete a prayer request if the user is not a member of the group' do
    post :destroy,
         params: { id: @prayer_request.id, group_id: @group.id },
         session: { logged_in_id: @other_person.id }
    expect(response).to be_forbidden
  end
end
