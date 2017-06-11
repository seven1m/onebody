require_relative '../rails_helper'

describe TagsController, type: :controller do
  before do
    @person = FactoryGirl.create(:person)
    @tag = FactoryGirl.create(:tag)
  end

  it 'should show a tag by id' do
    get :show, { id: @tag.id }, logged_in_id: @person.id
    expect(response).to be_success
    expect(assigns(:tag)).to eq(@tag)
  end

  it 'should show a tag by name' do
    get :show, { id: @tag.name }, logged_in_id: @person.id
    expect(response).to be_success
    expect(assigns(:tag)).to eq(@tag)
  end
end
