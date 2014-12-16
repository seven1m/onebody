require_relative '../rails_helper'

describe CustomReportsController, type: :controller do

  before do
    @user = FactoryGirl.create(:person)
    @custom_report = FactoryGirl.create(:custom_report)
  end

  context '#index' do
    context 'with authorisation' do
      before do
        @user.update_attributes!(admin: Admin.create!(run_reports: true))
      end
      it 'should redirect on the index action' do
        get :index, nil, logged_in_id: @user.id
        expect(response).to redirect_to(admin_reports_url)
      end
    end

    context 'without authorization' do
      it 'should fail authorization' do
        get :index, nil, logged_in_id: @user.id
        expect(response).to be_redirect
      end
    end
  end

  context '#show' do
    before do
      get :show, { id: @custom_report.id }, logged_in_id: @user.id
    end

    it 'renders the show template' do
      expect(response).to render_template(:show)
    end
  end

  context '#person' do
    before do
      get :show, { id: @custom_report.id }, logged_in_id: @user.id
    end

    it 'renders the show template' do
      expect(response).to render_template(:show)
    end
  end

  context '#create' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_reports: true))
    end

    it 'should create a new report' do
      get :new, nil, logged_in_id: @user.id
      expect(response).to be_success
      before = CustomReport.count
      post :create, { person_id: @user.id,
                      custom_report: { title: 'Test Report',
                                       body: 'Report X',
                                       category: '1' } },
           logged_in_id: @user.id
      expect(response).to be_redirect
      expect(CustomReport.count).to eq(before + 1)
      new_customreport = CustomReport.last
      expect(new_customreport.title).to eq('Test Report')
      expect(new_customreport.body).to eq('Report X')
      expect(new_customreport.category).to eq('1')
    end

  end

  context '#update' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_reports: true))
    end

    it 'should update an existing report' do
      get :edit, { id: @custom_report.id }, logged_in_id: @user.id
      expect(response).to be_success
      post :update, { id: @custom_report.id,
                      custom_report: { title: 'Testy Report',
                                       body: 'Report Y',
                                       category: '2' } },
           logged_in_id: @user.id
      expect(response).to be_redirect
    end
  end

  context '#destroy' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_reports: true))
      post :destroy, { id: @custom_report.id }, logged_in_id: @user.id
    end

    it 'should delete the custom report' do
      expect { @custom_report.reload }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should redirect to the report dashboard' do
      expect(response).to redirect_to(admin_reports_url)
    end
  end
end
