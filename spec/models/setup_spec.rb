require_relative '../rails_helper'

describe Setup, type: :model do
  let(:person) { FactoryGirl.build(:person) }
  let(:params) do
    ActionController::Parameters.new(person: {
                                       first_name: person.first_name,
                                       last_name:  person.last_name,
                                       email:      person.email,
                                       password:   person.password,
                                       password_confirmation: person.password
                                     },
                                     domain_name: 'church.io')
  end
  let(:setup) { Setup.new(params) }

  after { Site.current.update!(name: 'Default', host: 'example.com') }

  shared_examples 'a person initializier' do
    it 'Initializes a new Person with params attributes' do
      expect(setup.person).to be_a(Person)
      expect(setup.person.first_name).to eq person.first_name
      expect(setup.person.last_name).to  eq person.last_name
      expect(setup.person.email).to      eq person.email
    end
  end

  describe '#execute!' do
    context 'Happy Path' do
      before { setup.execute! }

      it_behaves_like 'a person initializier'

      it 'saves the new Person' do
        expect(setup.person).to be_persisted
      end

      it 'updates the current site`s host' do
        expect(setup.site.host).to eq('church.io')
      end
    end

    context 'with missing domain_name' do
      before do
        params[:domain_name] = nil
        setup.execute!
      end

      it_behaves_like 'a person initializier'

      it 'does not save the new Person' do
        expect(setup.person).to_not be_persisted
      end

      it 'adds errors to person' do
        expect(setup.person.errors.full_messages.to_s).to include('Enter the domain for this site')
      end
    end
  end
end
