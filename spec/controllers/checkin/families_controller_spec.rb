require_relative '../../rails_helper'

describe Checkin::FamiliesController, type: :controller do
  let(:family) { FactoryGirl.create(:family) }
  let(:user)   { FactoryGirl.create(:person) }

  describe '#show' do
    before do
      get :show,
          params: { id: family.id, format: :js },
          session: { logged_in_id: user.id },
          xhr: true
    end

    it 'renders the show template' do
      expect(response).to be_success
      expect(response).to render_template(:show)
    end

    it 'assigns attendance records' do
      expect(assigns[:attendance_records]).to eq({})
    end
  end

  describe '#new' do
    before do
      get :new,
          session: { logged_in_id: user.id },
          xhr: true
    end

    it 'renders the new template' do
      expect(response).to be_success
      expect(response).to render_template(:new)
    end

    it 'assigns new family and people' do
      expect(assigns[:family]).to be_a(Family)
      expect(assigns[:people].map(&:class)).to eq([Person] * 25)
      expect(assigns[:people].map(&:child?)).to eq([false] * 2 + [true] * 23)
    end
  end

  describe '#create' do
    def people_attributes(people, barcode_id = '1234567890')
      people = people.each_with_index
                     .each_with_object({}) { |(p, i), h| h[i.to_s] = p }
      {
        family: {
          barcode_id: barcode_id,
          people_attributes: people
        }
      }
    end

    context 'given 1 adult' do
      before do
        post :create,
             params: people_attributes([
               { first_name: 'Tim', last_name: 'Morgan' }
             ]),
             session: { logged_in_id: user.id }
      end

      it 'renders the create template' do
        expect(response).to be_success
        expect(response).to render_template(:create)
      end

      it 'creates a family and 1 person' do
        expect(Family.count).to eq(2)
        expect(Family.last.name).to eq('Tim Morgan')
        expect(Family.last.people.map(&:child?)).to eq([false])
        expect(Family.last.people.map(&:name)).to eq(['Tim Morgan'])
        expect(Family.last.people.map(&:status)).to eq(['pending'])
      end
    end

    context 'given 2 adults' do
      before do
        post :create,
             params: people_attributes([
               { first_name: 'Tim', last_name: 'Morgan' },
               { first_name: 'Jennie', last_name: 'Morgan' }
             ]),
             session: { logged_in_id: user.id }
      end

      it 'renders the create template' do
        expect(response).to be_success
        expect(response).to render_template(:create)
      end

      it 'creates a family and 2 people' do
        expect(Family.count).to eq(2)
        expect(Family.last.name).to eq('Tim & Jennie Morgan')
        expect(Family.last.people.map(&:child?)).to eq([false, false])
        expect(Family.last.people.map(&:name)).to eq(['Tim Morgan', 'Jennie Morgan'])
        expect(Family.last.people.map(&:status)).to eq(%w(pending pending))
      end
    end

    context 'given 1 adult and 1 kid missing a birthday' do
      before do
        post :create,
             params: people_attributes([
               { first_name: 'Tim', last_name: 'Morgan' },
               {},
               { first_name: 'Mac', last_name: 'Morgan', birthday: '' }
             ]),
             session: { logged_in_id: user.id }
      end

      it 'renders the new template' do
        expect(response).to be_success
        expect(response).to render_template(:new)
      end

      it 'does not create the family' do
        expect(Family.count).to eq(1)
      end

      it 'does not move the child up to the 2nd adult positition' do
        expect(assigns[:people].second.first_name).to be_nil
        expect(assigns[:people].third.first_name).to eq('Mac')
      end
    end

    context 'given 2 adults and 2 kids' do
      before do
        post :create,
             params: people_attributes([
               { first_name: 'Tim',    last_name: 'Morgan' },
               { first_name: 'Jennie', last_name: 'Morgan' },
               { first_name: 'Mac',    last_name: 'Morgan', birthday: '1/1/2014' },
               { first_name: 'Kai',    last_name: 'Morgan', birthday: '1/1/2015' }
             ]),
             session: { logged_in_id: user.id }
      end

      it 'renders the create template' do
        expect(response).to be_success
        expect(response).to render_template(:create)
      end

      it 'creates a family and 4 people' do
        expect(Family.count).to eq(2)
        expect(Family.last.name).to eq('Tim & Jennie Morgan')
        expect(Family.last.people.map(&:child?)).to eq([false, false, true, true])
        expect(Family.last.people.map(&:name)).to eq(['Tim Morgan', 'Jennie Morgan', 'Mac Morgan', 'Kai Morgan'])
        expect(Family.last.people.map(&:status)).to eq(['pending'] * 4)
      end
    end

    context 'given a kid without a birthday' do
      before do
        post :create,
             params: people_attributes([
               { first_name: 'Tim',    last_name: 'Morgan' },
               { first_name: 'Jennie', last_name: 'Morgan' },
               { first_name: 'Mac',    last_name: 'Morgan', birthday: '' },
               { first_name: 'Kai',    last_name: 'Morgan', birthday: '1/1/2015' }
             ]),
             session: { logged_in_id: user.id }
      end

      it 'renders the new template' do
        expect(response).to be_success
        expect(response).to render_template(:new)
      end

      it 'does not create a family' do
        expect(Family.count).to eq(1)
        expect(assigns[:family].errors[:base]).to match_array(match(/birthday/))
      end
    end

    context 'given no people' do
      before do
        post :create,
             params: people_attributes([]),
             session: { logged_in_id: user.id }
      end

      it 'renders the new template' do
        expect(response).to be_success
        expect(response).to render_template(:new)
      end

      it 'does not create a family' do
        expect(Family.count).to eq(1)
        expect(assigns[:family].errors[:base]).to match_array(match(/at least one person/))
      end
    end

    context 'given no parents' do
      before do
        post :create,
             params: people_attributes([
               {},
               {},
               { first_name: 'Mac', last_name: 'Morgan', birthday: '1/1/2014' }
             ]),
             session: { logged_in_id: user.id }
      end

      it 'renders the new template' do
        expect(response).to be_success
        expect(response).to render_template(:new)
      end

      it 'does not create a family' do
        expect(Family.count).to eq(1)
        expect(assigns[:family].errors[:base]).to match_array(match(/parent/))
      end
    end

    context 'given no barcode' do
      before do
        post :create,
             params: people_attributes([
               { first_name: 'Tim', last_name: 'Morgan' }
             ], ''),
             session: { logged_in_id: user.id }
      end

      it 'renders the new template' do
        expect(response).to be_success
        expect(response).to render_template(:new)
      end

      it 'does not create a family' do
        expect(Family.count).to eq(1)
        expect(assigns[:family].errors[:base]).to match_array(match(/scan.*card/))
      end
    end
  end

  describe '#update' do
    before do
      patch :update,
            params: {
              id: family.id,
              family: {
                barcode_id: '1234567890',
                alternate_barcode_id: '5678901234'
              },
              format: :js
            },
            session: {
              logged_in_id: user.id
            },
            xhr: true
    end

    it 'renders the update template' do
      expect(response).to be_success
      expect(response).to render_template(:update)
    end

    it 'updates the barcode' do
      expect(family.reload.barcode_id).to eq('1234567890')
      expect(family.alternate_barcode_id).to eq('5678901234')
    end
  end
end
