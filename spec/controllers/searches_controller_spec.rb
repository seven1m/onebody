require_relative '../rails_helper'

describe SearchesController, type: :controller do
  before do
    @user = FactoryGirl.create(:person)
    @person = FactoryGirl.create(:person, alias: 'Tim')
  end

  it 'renders the create template' do
    get :show, { name: 'tim' }, logged_in_id: @user.id
    expect(response).to render_template(:create)
    expect(assigns[:people]).to include(@person)
  end
end
