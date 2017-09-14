require 'rails_helper'

describe Administration::UpdatesController, type: :controller do
  render_views

  before do
    @person = FactoryGirl.create(:person)
    @admin = FactoryGirl.create(:person, :admin_manage_updates)
  end

  context '#index' do
    context 'unauthorized user' do
      it 'should return unauthorized' do
        get :index,
            session: { logged_in_id: @person.id }
        expect(response.status).to eq(401)
      end
    end

    context 'admin user' do
      before do
        @update = @person.updates.create!(
          data: {
            person: {
              birthday: Date.new(2000, 1, 1)
            }
          }
        )
        @update_complete = @person.updates.create!(complete: true)
        get :index,
            session: { logged_in_id: @admin.id }
      end

      it 'should render the index template' do
        expect(response).to render_template(:index)
      end

      it 'should show pending updates' do
        expect(assigns[:updates]).to eq([@update])
      end

      it 'should show dates formatted' do
        expect(response.body).to match(/<td>01\/01\/2000<\/td>/)
      end
    end
  end

  context '#update' do
    before do
      @update = @person.updates.create!(
        data: {
          person: {
            first_name: 'Tim',
            last_name: 'Morgan'
          },
          family: {
            name: 'Tim Morgan'
          }
        },
        complete: false
      )
    end

    it 'should mark the update complete' do
      put :update,
          params: { id: @update.id, update: { complete: 'true' } },
          session: { logged_in_id: @admin.id }
      expect(@update.reload.complete).to be
    end

    it 'should mark the update incomplete' do
      @update.update_attribute(:complete, true)
      put :update,
          params: { id: @update.id, update: { complete: 'false' } },
          session: { logged_in_id: @admin.id }
      expect(@update.reload.complete).not_to be
    end

    it 'should apply the update' do
      put :update,
          params: { id: @update.id, update: { apply: 'true' } },
          session: { logged_in_id: @admin.id }
      expect(@update.reload).to be_complete
      expect(@person.reload.first_name).to eq('Tim')
    end
  end

  context '#destroy' do
    before do
      @update = @person.updates.create!
    end

    it 'should destroy the update' do
      delete :destroy,
             params: { id: @update.id },
             session: { logged_in_id: @admin.id }
      expect { @update.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
