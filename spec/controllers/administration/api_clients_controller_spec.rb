require_relative '../../rails_helper'

describe Administration::ApiClientsController, type: :controller do
  render_views

  before do
    @user = FactoryGirl.create(:person)
  end

  context 'GET #index' do
    context 'as an administrator' do
      before do
        @user.update_attributes!(admin: Admin.create!)
      end
      it 'should render the :index template' do
        get :index, nil, logged_in_id: @user.id
        expect(response.status).to eq(200)
        expect(response).to render_template(:index)
      end
    end

    context 'without administrator privileges' do
      it 'should fail authorization' do
        get :index, nil, logged_in_id: @user.id
        expect(response.status).to eq(401)
      end
    end
  end

  context 'GET #new' do
    context 'as an administrator' do
      before do
        @user.update_attributes!(admin: Admin.create!)
      end
      it 'should render the :new template' do
        get :new, nil, logged_in_id: @user.id
        expect(response.status).to eq(200)
        expect(response).to render_template(:new)
      end
    end

    context 'without administrator privileges' do
      it 'should fail authorization' do
        get :new, nil, logged_in_id: @user.id
        expect(response.status).to eq(401)
      end
    end
  end

end