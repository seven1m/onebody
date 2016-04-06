require_relative '../rails_helper'

describe SearchesController, type: :controller do
  before do
    @vanilla_person = FactoryGirl.create(:person)
    @person_with_nickname = FactoryGirl.create(:person, alias: 'Slappy')
  end

  it 'should force log in' do
    get :show
    expect(response).to redirect_to '/session/new?from=%2Fsearch'
  end

  it 'should return all members without parameters' do
    get :show, nil, logged_in_id: @vanilla_person.id
    expect(response).to be_success
  end

  it 'should redirect to person_with_nickname' do
    get :show, { name: 'slappy' }, logged_in_id: @vanilla_person.id
    expect(response).to redirect_to person_url @person_with_nickname
  end
end
