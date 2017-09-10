require_relative '../rails_helper'

describe SearchesController, type: :controller do
  before do
    @user = FactoryGirl.create(:person)
    @person = FactoryGirl.create(:person, alias: 'Tim', first_name: 'Timothy', last_name: 'Morgan')
  end

  it 'renders the create template' do
    get :show,
        params: { name: 'tim' },
        session: { logged_in_id: @user.id }
    expect(response).to render_template(:create)
    expect(assigns[:people]).to include(@person)
  end

  context 'when direct=true is specified' do
    it 'redirects to the person if the name matches' do
      get :show,
          params: { name: 'Timothy Morgan', direct: true },
          session: { logged_in_id: @user.id }
      expect(response).to redirect_to(@person)
    end
  end
end
