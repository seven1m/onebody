require_relative '../rails_helper'

describe SearchesController, type: :controller do
  let(:user) { FactoryGirl.create(:person) }

  describe '#create' do
    context 'given a name' do
      before do
        post :create, { name: 'John' }, logged_in_id: user.id
      end

      it 'performs a person search' do
        expect(assigns[:search]).to be_a(PersonSearch)
        expect(response).to render_template(:create)
      end
    end

    context 'given a family name and format is js' do
      before do
        post :create, {
          family_name: 'John',
          select_family: true,
          format: :js
        }, logged_in_id: user.id
      end

      it 'performs a family search' do
        expect(assigns[:search]).to be_a(FamilySearch)
        expect(response).to render_template(:create)
      end
    end
  end
end
