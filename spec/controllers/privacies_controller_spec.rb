require_relative '../rails_helper'

describe PrivaciesController, type: :controller do
  let(:group)      { FactoryGirl.create(:group) }
  let(:user)       { FactoryGirl.create(:person) }
  let(:membership) { group.memberships.create(person: user) }

  describe '#edit' do
    context 'editing my own profile' do
      before do
        get :edit,
            params: { person_id: user.id },
            session: { logged_in_id: user.id }
      end

      it 'renders the edit template' do
        expect(response).to render_template(:edit)
      end
    end

    context "editing someone else's profile" do
      let(:stranger) { FactoryGirl.create(:person) }

      before do
        get :edit,
            params: { person_id: stranger.id },
            session: { logged_in_id: user.id }
      end

      it 'returns unauthorized' do
        expect(response.status).to eq(401)
      end

      context 'user is an adult in the same family' do
        let(:user) { FactoryGirl.create(:person, family: stranger.family) }

        it 'renders the edit template' do
          expect(response).to render_template(:edit)
        end
      end

      context 'user is an admin' do
        let(:user) { FactoryGirl.create(:person, :admin_edit_profiles) }

        it 'renders the edit template' do
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe '#update' do
    context "editing someone else's profile" do
      let(:stranger) { FactoryGirl.create(:person) }

      before do
        patch :update,
              params: {
                person_id: stranger.id,
                family: { visible: '0' }
              },
              session: { logged_in_id: user.id }
      end

      it 'returns unauthorized' do
        expect(response.status).to eq(401)
      end
    end

    context 'updating my own profile' do
      before do
        patch :update,
              params: {
                person_id: user.id,
                family: {
                  people_attributes: {
                    '0' => {
                      id:                 user.id,
                      share_mobile_phone: '1',
                      share_home_phone:   '0'
                    }
                  }
                }
              },
              session: { logged_in_id: user.id }
      end

      it 'updates privacy on the person record and redirects' do
        expect(user.reload.share_mobile_phone?).to eq(true)
        expect(user.reload.share_home_phone?).to eq(false)
        expect(response).to redirect_to(person_path(user))
      end
    end

    context 'updating group membership privacy' do
      before do
        patch :update,
              params: {
                person_id: user.id,
                family: {
                  people_attributes: {
                    '0' => {
                      id:                 user.id,
                      share_mobile_phone: '0'
                    }
                  }
                },
                memberships: {
                  membership.id => {
                    share_mobile_phone: '1'
                  }
                }
              },
              session: { logged_in_id: user.id }
      end

      it 'updates privacy on the group membership record' do
        expect(membership.reload.share_mobile_phone?).to eq(true)
      end
    end

    context 'updating family visibility' do
      before do
        patch :update,
              params: {
                person_id: user.id,
                family: { visible: '0' }
              },
              session: { logged_in_id: user.id }
      end

      it 'changes family visibility' do
        expect(user.family.reload.visible?).to eq(false)
      end
    end

    context 'giving parental consent' do
      let(:child) { FactoryGirl.create(:person, family: user.family, child: true) }

      before do
        patch :update,
              params: {
                person_id: child.id,
                agree: I18n.t('privacies.i_agree') + '.',
                agree_commit: true
              },
              session: { logged_in_id: user.id }
      end

      it 'saves the consent on the child' do
        expect(child.reload.parental_consent).to match(/John Smith \(\d+\) \d{4}-\d{2}-\d{2} \d+:\d+:\d+/)
      end
    end
  end
end
