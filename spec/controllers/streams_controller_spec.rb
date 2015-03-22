require_relative '../rails_helper'

describe StreamsController, type: :controller do
  before do
    @person = FactoryGirl.create(:person)
    @friend = FactoryGirl.create(:person)
  end

  it 'should show a stream' do
    get :show, nil, {logged_in_id: @person.id}
    expect(response).to be_success
  end
end
