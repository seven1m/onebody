require_relative '../rails_helper'

describe AttendanceController, type: :controller do
  render_views

  let(:group) { FactoryGirl.create(:group) }

  describe '#index' do
    context 'given user is a group admin' do
      let!(:user)       { FactoryGirl.create(:person) }
      let!(:membership) { group.memberships.create!(person: user, admin: true) }

      context do
        before do
          get :index,
              params: {
                attended_at: '2009-12-01',
                group_id: group.id
              },
              session: { logged_in_id: user.id }
        end

        it 'renders the index template' do
          expect(response).to render_template(:index)
        end
      end

      context 'given no date' do
        before do
          get :index,
              params: {
                group_id: group.id
              },
              session: { logged_in_id: user.id }
        end

        it 'uses the current date' do
          expect(assigns[:attended_at].strftime('%Y-%m-%d')).to eq(
            Date.current.strftime('%Y-%m-%d')
          )
          expect(flash[:warning]).to be_nil
        end
      end

      context 'given an invalid date' do
        before do
          get :index,
              params: {
                attended_at: '2009',
                group_id: group.id
              },
              session: { logged_in_id: user.id }
        end

        it 'uses the current date and shows a warning' do
          expect(assigns[:attended_at].strftime('%Y-%m-%d')).to eq(
            Date.current.strftime('%Y-%m-%d')
          )
          expect(flash[:warning]).to be
        end
      end
    end

    context 'given public=true and token' do
      before do
        get :index,
            params: { attended_at: '2009-12-01',
                      group_id: group.id,
                      public: 'true',
                      token: group.share_token }
      end

      it 'renders the public_index template' do
        expect(response).to render_template(:public_index)
      end
    end

    context 'given user is not a group admin' do
      let!(:user)       { FactoryGirl.create(:person) }
      let!(:membership) { group.memberships.create!(person: user) }

      before do
        get :index,
            params: {
              attended_at: '2009-12-01',
              group_id: group.id
            },
            session: { logged_in_id: user.id }
      end

      it 'renders an error message' do
        expect(response.status).to eq(401)
      end
    end

    context 'given attendance is disabled on the group' do
      let!(:group)      { FactoryGirl.create(:group, attendance: false) }
      let!(:user)       { FactoryGirl.create(:person) }
      let!(:membership) { group.memberships.create!(person: user, admin: true) }

      before do
        get :index,
            params: {
              attended_at: '2009-12-01',
              group_id: group.id
            },
            session: { logged_in_id: user.id }
      end

      it 'renders an error' do
        expect(response).to be_bad_request
      end
    end
  end

  describe '#create' do
    context 'user is administrator' do
      let!(:user)       { FactoryGirl.create(:person) }
      let!(:membership) { group.memberships.create!(person: user, admin: true) }
      let(:attendee1)   { FactoryGirl.create(:person) }
      let(:attendee2)   { FactoryGirl.create(:person) }

      context do
        before do
          post :create,
               params: {
                 attended_at: '2009-12-01 09:00',
                 group_id: group.id,
                 ids: [attendee1.id]
               },
               session: { logged_in_id: user.id }
        end

        it 'creates attendance records' do
          records = group.attendance_records
          expect(records.count).to eq(1)
          expect(records.first.person_id).to eq(attendee1.id)
          expect(records.first.attended_at).to eq(Time.utc(2009, 12, 1, 9, 0))
        end
      end

      context 'given format is json' do
        before do
          post :create,
               params: {
                 attended_at: '2009-12-01 09:00',
                 group_id: group.id,
                 ids: [attendee1.id],
                 format: :json
               },
               session: { logged_in_id: user.id }
        end

        it 'renders json response' do
          expect(JSON.parse(response.body)).to eq(
            'status' => 'success'
          )
        end
      end

      context 'given check-in time without date' do
        before do
          post :create,
               params: {
                 attended_at: '9:30 AM',
                 group_id: group.id,
                 ids: [attendee1.id]
               },
               session: { logged_in_id: user.id }
        end

        it 'creates attendance records' do
          records = group.attendance_records
          expect(records.count).to eq(1)
          expect(records.first.person_id).to eq(attendee1.id)
          time = records.first.attended_at.strftime('%Y-%m-%d %H:%M:%S %z')
          expect(time).to eq(Date.current.strftime('%Y-%m-%d') + ' 09:30:00 +0000')
        end
      end

      context 'given existing records for this time' do
        let!(:existing1) { group.attendance_records.create!(person: attendee1, attended_at: Time.new(2009, 12, 1, 9, 0)) }
        let!(:existing2) { group.attendance_records.create!(person: attendee2, attended_at: Time.new(2009, 12, 1, 9, 0)) }

        before do
          post :create,
               params: {
                 attended_at: '2009-12-01 09:00',
                 group_id: group.id,
                 ids: [attendee1.id]
               },
               session: { logged_in_id: user.id }
        end

        it 'deletes old records for the same person' do
          records = group.attendance_records.reload
          expect(records.map(&:attributes)).to contain_exactly(
            include('person_id' => attendee1.id),
            include('person_id' => attendee2.id)
          )
        end
      end

      context 'given person not in database' do
        before do
          post :create,
               params: {
                 attended_at: '2009-12-01 09:00',
                 group_id: group.id,
                 person: {
                   first_name: 'John',
                   last_name:  'Smith'
                 }
               },
               session: { logged_in_id: user.id }
        end

        it 'creates a record not attached to a person record' do
          records = group.attendance_records.reload
          expect(records.map(&:attributes)).to contain_exactly(
            include('person_id' => nil, 'first_name' => 'John', 'last_name' => 'Smith')
          )
        end
      end
    end

    context 'user is not administrator' do
      let!(:user) { FactoryGirl.create(:person) }

      before do
        post :create,
             params: {
               attended_at: '2009-12-01 09:00',
               group_id: group.id,
               ids: [1]
             },
             session: { logged_in_id: user.id }
      end

      it 'renders an error message' do
        expect(response.status).to eq(401)
      end
    end

    context 'group_id is 0 (bogus submission from legacy check-in software)' do
      let!(:user) { FactoryGirl.create(:person) }

      before do
        post :create,
             params: {
               attended_at: '2009-12-01 09:00',
               group_id: '0',
               ids: [1]
             },
             session: { logged_in_id: user.id }
      end

      it 'renders 404' do
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#batch' do
    let(:attendee) { FactoryGirl.create(:person) }

    context 'from logged in user' do
      let!(:user)       { FactoryGirl.create(:person) }
      let!(:membership) { group.memberships.create!(person: user, admin: true) }

      context do
        before do
          post :batch,
               params: {
                 attended_at: '2009-12-01',
                 group_id: group.id,
                 ids: [attendee.id]
               },
               session: { logged_in_id: user.id }
        end

        it 'creates attendance records' do
          records = group.attendance_records
          expect(records.count).to eq(1)
          expect(records.first.person_id).to eq(attendee.id)
          expect(records.first.attended_at).to eq(Time.utc(2009, 12, 1, 0, 0))
        end

        it 'emails the report' do
          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.count).to eq(1)
          expect(deliveries.first.subject).to eq("Attendance Submission for #{group.name}")
        end
      end

      context 'given an existing record' do
        let!(:existing) { group.attendance_records.create!(person_id: 0, attended_at: Time.new(2009, 12, 1, 9, 0)) }

        before do
          post :batch,
               params: {
                 attended_at: '2009-12-01',
                 group_id: group.id,
                 ids: [attendee.id]
               },
               session: { logged_in_id: user.id }
        end

        it 'deletes the existing record' do
          expect { existing.reload }.to raise_error(ActiveRecord::RecordNotFound)
          records = group.attendance_records
          expect(records.count).to eq(1)
        end
      end

      context 'given invalid date format' do
        before do
          post :batch,
               params: {
                 attended_at: '99-99-99',
                 group_id: group.id,
                 ids: [attendee.id]
               },
               session: { logged_in_id: user.id }
        end

        render_views

        it 'renders an error' do
          expect(response.body).to match(/Could not recognize date/)
          expect(response).to be_bad_request
        end
      end
    end

    context 'using public interface and share token' do
      context 'using valid token' do
        context do
          before do
            post :batch,
                 params: { group_id:    group.id,
                           public:      true,
                           token:       group.share_token,
                           ids:         [attendee.id],
                           attended_at: '01/13/2020' }
          end

          render_views

          it 'returns success' do
            expect(response.body).to match(/attendance submitted/i)
            expect(response).to render_template(:signed_out)
          end
        end

        context 'with notes' do
          before do
            post :batch,
                 params: { group_id:    group.id,
                           public:      true,
                           token:       group.share_token,
                           ids:         [attendee.id],
                           attended_at: '01/13/2020',
                           notes:       'test note' }
          end

          render_views

          it 'emails the note' do
            deliveries = ActionMailer::Base.deliveries
            expect(deliveries.count).to eq(1)
            expect(deliveries.first.subject).to eq("Attendance Submission for #{group.name}")
            expect(deliveries.first.body).to match(/test note/)
          end
        end
      end

      context 'using bad token' do
        before do
          post :batch,
               params: { group_id:    group.id,
                         public:      true,
                         token:       'abc',
                         ids:         [attendee.id],
                         attended_at: '01/13/2020' }
        end

        it 'returns unauthorized' do
          expect(response.status).to eq(401)
          expect(response).to render_template(:signed_out)
        end
      end
    end
  end
end
