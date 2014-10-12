require_relative '../spec_helper'

describe AttendanceController do

  before do
    @person = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group, creator_id: @person.id, category: 'Small Groups')
    @group.memberships.create(person: @person, admin: true)
  end

  it "should store and retrieve attendance records based on date" do
    post :batch, {attended_at: '2009-12-01', group_id: @group.id, ids: [@person.id]}, {logged_in_id: @person.id}
    get  :index, {attended_at: '2009-12-01', group_id: @group.id}, {logged_in_id: @person.id}
    expect(assigns(:records).length).to eq(1)
    person, attended = assigns(:records).first
    expect(attended).to be
  end

  it "should overwrite existing records on batch" do
    post :batch, {attended_at: '2009-12-01', group_id: @group.id, ids: [@person.id]}, {logged_in_id: @person.id}
    post :batch, {attended_at: '2009-12-01', group_id: @group.id, ids: []}, {logged_in_id: @person.id}
    get  :index, {attended_at: '2009-12-01', group_id: @group.id}, {logged_in_id: @person.id}
    expect(assigns(:records).length).to eq(1)
    person, attended = assigns(:records).first
    expect(attended).not_to be
  end

  it "should overwrite existing records for the same person and same time on create" do
    post :create, {attended_at: '2009-12-01 09:00', group_id: @group.id, ids: [@person.id]}, {logged_in_id: @person.id}
    expect(AttendanceRecord.where(person_id: @person.id, attended_at: "2009-12-01 09:00:00").count).to eq(1)
    post :create, {attended_at: '2009-12-01 09:00', group_id: @group.id, ids: [@person.id]}, {logged_in_id: @person.id}
    expect(AttendanceRecord.where(person_id: @person.id, attended_at: "2009-12-01 09:00:00").count).to eq(1)
  end

  it "should record attendance for people in the database" do
    post :create, {attended_at: '2009-12-01 9:00', group_id: @group.id, ids: [@person.id]}, {logged_in_id: @person.id}
    expect(response).to be_redirect
    @records = AttendanceRecord.all
    expect(@records.length).to eq(1)
    expect(@records.first.first_name).to eq(@person.first_name)
  end

  it "should record attendance for people not in the database" do
    post :create, {attended_at: '2009-12-01 9:00', group_id: @group.id, person: {'first_name' => 'Jimmy', 'last_name' => 'Smith', 'age' => '2 yr'}}, {logged_in_id: @person.id}
    expect(response).to be_redirect
    @records = AttendanceRecord.all
    expect(@records.length).to eq(1)
    expect(@records.first.first_name).to eq("Jimmy")
  end

  it "should respond to a json request with status='success'" do
    post :create, {attended_at: '2009-12-01 9:00', group_id: @group.id, ids: [@person.id], person: {'first_name' => 'Jimmy', 'last_name' => 'Smith', 'age' => '2 yr'}, format: 'json'}, {logged_in_id: @person.id}
    expect(response).to be_success
    expect(ActiveSupport::JSON.decode(@response.body)["status"]).to eq("success")
  end

  describe 'public interface using share token' do
    describe 'GET index' do
      context 'using valid token' do
        before do
          get :index, { group_id: @group.id, public: true, token: @group.share_token }
        end

        it 'renders the public index template with signed_out layout' do
          expect(response).to render_template(:public_index)
          expect(response).to render_template(:signed_out)
        end
      end

      context 'using bad token' do
        before do
          get :index, { group_id: @group.id, public: true, token: 'abc' }
        end

        it 'returns unauthorized' do
          expect(response).to be_unauthorized
          expect(response).to render_template(:signed_out)
        end
      end
    end

    describe 'POST batch' do
      context 'using valid token' do
        before do
          post :batch, {
            group_id:    @group.id,
            public:      true,
            token:       @group.share_token,
            ids:         [@person.id],
            attended_at: '01/13/2020'
          }
        end

        render_views

        it 'returns success' do
          expect(response.body).to match(/attendance submitted/i)
          expect(response).to render_template(:signed_out)
        end
      end

      context 'using bad token' do
        before do
          post :batch, {
            group_id:    @group.id,
            public:      true,
            token:       'abc',
            ids:         [@person.id],
            attended_at: '01/13/2020'
          }
        end

        it 'returns unauthorized' do
          expect(response).to be_unauthorized
          expect(response).to render_template(:signed_out)
        end
      end
    end
  end

end
