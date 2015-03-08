require_relative '../rails_helper'

describe ImportRow do
  describe 'validations' do
    it { should validate_presence_of(:import) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:sequence) }
  end

  describe '#import_attributes_as_hash' do
    subject { FactoryGirl.create(:import_row, :with_attributes) }

    it 'returns a hash' do
      expect(subject.import_attributes_as_hash).to include(
        'foo' => 'bar',
        'baz' => 'quz'
      )
    end
  end

  describe '#match_person' do
    let(:import) do
      FactoryGirl.create(
        :import,
        mappings: {
          'id'    => 'id',
          'first' => 'first_name',
          'last'  => 'last_name',
          'phone' => 'mobile_phone',
          'email' => 'email'
        }
      )
    end

    context 'given match strategy by_id_only and matching person' do
      before do
        import.update_attribute(:match_strategy, 'by_id_only')
      end

      let!(:person) { FactoryGirl.create(:person, first_name: 'James', last_name: 'Smith') }

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'id', value: person.id, sequence: 1 },
          ]
        )
      end

      it 'returns the person' do
        expect(subject.match_person).to eq(person)
      end
    end

    context 'given match strategy by_name and matching person' do
      before do
        import.update_attribute(:match_strategy, 'by_name')
      end

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'first', value: 'James', sequence: 1 },
            { import: import, name: 'last', value: 'Smith', sequence: 2 }
          ]
        )
      end

      let!(:person) { FactoryGirl.create(:person, first_name: 'James', last_name: 'Smith') }

      it 'returns the person' do
        expect(subject.match_person).to eq(person)
      end
    end

    context 'given match strategy by_contact_info and matching mobile phone' do
      before do
        import.update_attribute(:match_strategy, 'by_contact_info')
      end

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'first', value: 'James', sequence: 1 },
            { import: import, name: 'last', value: 'Smith', sequence: 2 },
            { import: import, name: 'phone', value: '(918) 123-4567', sequence: 3 }
          ]
        )
      end

      let!(:person) { FactoryGirl.create(:person, mobile_phone: '9181234567') }

      it 'returns the person' do
        expect(subject.match_person).to eq(person)
      end
    end

    context 'given match strategy by_contact_info and matching email address' do
      before do
        import.update_attribute(:match_strategy, 'by_contact_info')
      end

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'first', value: 'James', sequence: 1 },
            { import: import, name: 'last', value: 'Smith', sequence: 2 },
            { import: import, name: 'email', value: 'TIM@timmorgan.org', sequence: 3 }
          ]
        )
      end

      let!(:person) { FactoryGirl.create(:person, email: 'tim@timmorgan.org') }

      it 'returns the person' do
        expect(subject.match_person).to eq(person)
      end
    end
  end
end
