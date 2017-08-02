require_relative '../rails_helper'

describe MembershipsController, type: :controller do
  describe '#show' do
    let(:group) { FactoryGirl.create(:group) }
    let(:person) { FactoryGirl.create(:person) }
    let!(:membership) { group.memberships.create!(person: person) }

    context 'given email param' do
      before do
        get :show, { group_id: group.id, id: person.id, email: 'off' }, logged_in_id: person.id
      end

      it 'renders the email template' do
        expect(controller).to render_template(:email)
      end
    end
  end

  describe '#index' do
    let(:user) { FactoryGirl.create(:person) }

    context 'user is a group member' do
      let(:group) { FactoryGirl.create(:group) }
      let!(:membership) { group.memberships.create!(person: user) }

      before do
        get :index, { group_id: group.id }, logged_in_id: user.id
      end

      it 'assigns memberships' do
        expect(assigns[:memberships].count).to eq(1)
      end

      it 'assigns membership requests' do
        expect(assigns[:requests].count).to eq(0)
      end
    end

    context 'user is not a group member and group is private' do
      let(:group) { FactoryGirl.create(:group, private: true) }

      before do
        get :index, { group_id: group.id }, logged_in_id: user.id
      end

      it 'renders unauthorized' do
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#create' do
    context 'group requires approval' do
      let(:group) { FactoryGirl.create(:group, approval_required_to_join: true) }

      context 'user is an admin' do
        let(:user) { FactoryGirl.create(:person, :admin_manage_groups) }

        before do
          request.env['HTTP_REFERER'] = group_memberships_path(group)
          post :create, {
            group_id: group.id,
            id: user.id
          }, logged_in_id: user.id
        end

        it 'creates the membership' do
          membership = user.memberships.last
          expect(membership.group).to eq(group)
        end

        it 'redirects back' do
          expect(response).to be_redirect
        end
      end

      context 'user is not an admin' do
        let(:user) { FactoryGirl.create(:person) }

        before do
          request.env['HTTP_REFERER'] = group_memberships_path(group)
          post :create, {
            group_id: group.id,
            id: user.id
          }, logged_in_id: user.id
        end

        it 'creates a membership request' do
          membership_request = user.membership_requests.last
          expect(membership_request.group).to eq(group)
        end

        it 'redirects back' do
          expect(response).to be_redirect
        end
      end
    end

    context 'group does not require approval' do
      let(:group) { FactoryGirl.create(:group, approval_required_to_join: false) }
      let(:user) { FactoryGirl.create(:person) }

      before do
        request.env['HTTP_REFERER'] = group_memberships_path(group)
        post :create, {
          group_id: group.id,
          id: user.id
        }, logged_in_id: user.id
      end

      it 'creates the membership' do
        membership = user.memberships.last
        expect(membership.group).to eq(group)
      end

      it 'redirects back' do
        expect(response).to be_redirect
      end
    end
  end

  describe '#update' do
    let(:group)       { FactoryGirl.create(:group) }
    let(:person)      { FactoryGirl.create(:person) }
    let!(:membership) { group.memberships.create!(person: person) }

    context 'PUT with param email=on' do
      context do
        before do
          xhr :put, :update, {
            group_id: group.id,
            id: person.id,
            email: 'on',
            format: :js
          }, logged_in_id: person.id
        end

        it 'enables email for the person' do
          expect(membership.reload.get_email).to eq(true)
        end

        it 'renders the update template' do
          expect(response).to be_success
          expect(response).to render_template(:update)
        end
      end

      context 'user is a different user' do
        let(:user) { FactoryGirl.create(:person) }

        before do
          xhr :put, :update, {
            group_id: group.id,
            id: person.id,
            email: 'on',
            format: :js
          }, logged_in_id: user.id
        end

        it 'renders unauthorized' do
          expect(response.status).to eq(401)
        end
      end

      context 'user is a group admin' do
        let(:user) { FactoryGirl.create(:person, :admin_manage_groups) }

        before do
          xhr :put, :update, {
            group_id: group.id,
            id: person.id,
            email: 'on',
            format: :js
          }, logged_in_id: user.id
        end

        it 'returns success' do
          expect(response).to be_success
        end
      end
    end

    context 'PUT with param email=off' do
      before do
        xhr :put, :update, {
          group_id: group.id,
          id: person.id,
          email: 'off',
          format: :js
        }, logged_in_id: person.id
      end

      it 'disables email for the person' do
        expect(membership.reload.get_email).to eq(false)
      end

      it 'renders the update template' do
        expect(response).to be_success
        expect(response).to render_template(:update)
      end
    end

    context 'PUT with param promote=true' do
      context 'user is an admin' do
        let(:user) { FactoryGirl.create(:person, :admin_manage_groups) }

        before do
          request.env['HTTP_REFERER'] = group_memberships_path(group)
          xhr :put, :update, {
            group_id: group.id,
            id: membership.id,
            promote: 'true',
            format: :js
          }, logged_in_id: user.id
        end

        it 'makes the person a group admin' do
          expect(membership.reload.admin).to eq(true)
        end

        it 'renders the js template' do
          expect(response).to render_template('update_admin.js.erb')
        end
      end

      context 'user is not an admin' do
        before do
          request.env['HTTP_REFERER'] = group_memberships_path(group)
          xhr :put, :update, {
            group_id: group.id,
            id: membership.id,
            promote: 'true',
            format: :js
          }, logged_in_id: person.id
        end

        it 'renders unauthorized' do
          expect(response.status).to eq(401)
        end
      end
    end

    context 'PUT with param promote=false' do
      context 'user is an admin' do
        let(:user) { FactoryGirl.create(:person, :admin_manage_groups) }

        before do
          request.env['HTTP_REFERER'] = group_memberships_path(group)
          xhr :put, :update, {
            group_id: group.id,
            id: membership.id,
            promote: 'false',
            format: :js
          }, logged_in_id: user.id
        end

        it 'makes the person a regular group member' do
          expect(membership.reload.admin).to eq(false)
        end

        it 'renders the js template' do
          expect(response).to render_template('update_admin.js.erb')
        end
      end
    end
  end

  describe '#destroy' do
    let(:group)       { FactoryGirl.create(:group) }
    let(:person)      { FactoryGirl.create(:person) }
    let!(:membership) { group.memberships.create!(person: person) }

    context do
      before do
        xhr :delete, :destroy, {
          group_id: group.id,
          id: person.id,
          format: :js
        }, logged_in_id: person.id
      end

      it 'destroys the membership' do
        expect { membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'renders the destroy template' do
        expect(response).to render_template(:destroy)
      end
    end

    context 'person is last admin' do
      let!(:membership) { group.memberships.create!(person: person, admin: true) }

      before do
        xhr :delete, :destroy, {
          group_id: group.id,
          id: person.id,
          format: :js
        }, logged_in_id: person.id
      end

      it 'does not destroy the membership' do
        expect(membership.reload).to be
      end

      it 'sets a flash message' do
        expect(flash[:warning]).to eq(I18n.t('groups.last_admin_remove', name: person.name))
      end
    end
  end

  describe '#batch' do
    let(:group)  { FactoryGirl.create(:group) }
    let(:user)   { FactoryGirl.create(:person, :admin_manage_groups) }
    let(:person) { FactoryGirl.create(:person) }

    context 'given an existing membership request' do
      let!(:membership_request) { person.membership_requests.create!(group: group) }

      context 'POST' do
        before do
          xhr :post, :batch, { group_id: group.id, ids: [person.id], format: :js }, logged_in_id: user.id
        end

        it 'creates membership records for each id given' do
          expect(group.memberships.reload.map(&:person)).to eq([person])
        end

        it 'destroys existing membership requests' do
          expect(person.membership_requests.count).to eq(0)
        end

        it 'renders the batch template with added memberships' do
          expect(assigns[:added].map(&:attributes)).to match([
                                                               include('person_id' => person.id, 'group_id' => group.id)
                                                             ])
          expect(response).to render_template(:batch)
        end
      end

      context 'POST commit=ignore' do
        before do
          xhr :post, :batch, {
            group_id: group.id,
            ids: [person.id],
            commit: 'ignore',
            format: :js
          }, logged_in_id: user.id
        end

        it 'does not create new membership records' do
          expect(group.memberships.count).to eq(0)
        end

        it 'destroys existing membership requests' do
          expect(person.membership_requests.count).to eq(0)
        end

        it 'renders the batch template with no added memberships' do
          expect(assigns[:added]).to eq([])
          expect(response).to render_template(:batch)
        end
      end

      context 'DELETE' do
        let!(:membership) { group.memberships.create!(person: person) }

        before do
          xhr :delete, :batch, {
            group_id: group.id,
            ids: [person.id],
            format: :js
          }, logged_in_id: user.id
        end

        it 'destroys memberships' do
          expect { membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect(person.memberships.count).to eq(0)
        end

        it 'renders the batch template with no added memberships' do
          expect(assigns[:added]).to eq([])
          expect(response).to render_template(:batch)
        end
      end

      context 'DELETE when person is last admin' do
        let!(:membership) { group.memberships.create!(person: person, admin: true) }

        before do
          xhr :delete, :batch, {
            group_id: group.id,
            ids: [person.id],
            format: :js
          }, logged_in_id: user.id
        end

        it 'does not destroy the membership of the last admin' do
          expect(membership.reload).to be
        end

        it 'renders the batch template with no added memberships' do
          expect(assigns[:added]).to eq([])
          expect(response).to render_template(:batch)
        end
      end

      context 'POST when user is not a group admin' do
        let(:user) { FactoryGirl.create(:person) }

        before do
          xhr :post, :batch, { group_id: group.id, ids: [person.id], format: :js }, logged_in_id: user.id
        end

        render_views

        it 'renders unauthorized' do
          expect(response.body).to match(/not authorized/)
        end
      end
    end
  end
end
