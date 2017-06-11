require_relative '../rails_helper'

describe StreamsController, type: :controller do
  before do
    @person = FactoryGirl.create(:person)
    @friend = FactoryGirl.create(:person)
  end

  it 'should show a stream' do
    Setting.set(:features, :stream, true)
    get :show, nil, logged_in_id: @person.id
    expect(response).to be_success
  end

  it 'should show search' do
    Setting.set(:features, :stream, false)
    get :show, nil, logged_in_id: @person.id
    expect(response).to redirect_to '/search'
  end
end
