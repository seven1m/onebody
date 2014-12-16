require_relative '../../rails_helper'

describe Administration::DashboardsController, "GET /show", type: :controller do
  render_views

  context "an unauthorized user" do
    let!(:person) { FactoryGirl.create(:person) }
    
    it 'should return unauthorized' do
      get :show, nil, { logged_in_id: person.id }
      expect(response.status).to eq(401)
    end
  end
  
  context "an authorized user" do
    let!(:admin) { FactoryGirl.create(:person, :admin_manage_updates) }
    
    it 'should return unauthorized' do
      get :show, nil, { logged_in_id: admin.id }
      expect(response.status).to eq(200)
    end
  end
end
