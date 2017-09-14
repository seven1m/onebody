require_relative '../rails_helper'

describe ImportRow, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:import) }
    it { should validate_presence_of(:sequence) }
  end

  describe '#import_attributes_as_hash' do
    subject { FactoryGirl.create(:import_row, :with_attributes) }

    it 'returns a hash' do
      expect(subject.import_attributes_as_hash).to include(
        'first' => 'foo',
        'last'  => 'bar'
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
            { import: import, name: 'id', value: person.id, sequence: 1 }
          ]
        )
      end

      it 'returns the person' do
        expect(subject.match_person).to eq(person)
      end

      it 'sets matched_person_by' do
        subject.match_person
        expect(subject.matched_person_by).to eq('matched_person_by_id')
      end
    end

    context 'given match strategy by_name and matching person found by id' do
      before do
        import.update_attribute(:match_strategy, 'by_name')
      end

      let!(:person1) { FactoryGirl.create(:person, first_name: 'James', last_name: 'Smith') }
      let!(:person2) { FactoryGirl.create(:person, first_name: 'James', last_name: 'Smith') }

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'id',    value: person2.id, sequence: 1 },
            { import: import, name: 'first', value: 'James',    sequence: 2 },
            { import: import, name: 'last',  value: 'Smith',    sequence: 3 }
          ]
        )
      end

      it 'returns the person matching by id' do
        expect(subject.match_person).to eq(person2)
      end

      it 'sets matched_person_by' do
        subject.match_person
        expect(subject.matched_person_by).to eq('matched_person_by_id')
      end
    end

    context 'given match strategy by_name and matching person' do
      before do
        import.update_attribute(:match_strategy, 'by_name')
      end

      let!(:person) { FactoryGirl.create(:person, first_name: 'James', last_name: 'Smith') }

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

      it 'returns the person' do
        expect(subject.match_person).to eq(person)
      end

      it 'sets matched_person_by' do
        subject.match_person
        expect(subject.matched_person_by).to eq('matched_person_by_name')
      end
    end

    context 'given match strategy by_contact_info and matching mobile phone' do
      before do
        import.update_attribute(:match_strategy, 'by_contact_info')
      end

      let!(:person) { FactoryGirl.create(:person, mobile_phone: '9181234567') }

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

      it 'returns the person' do
        expect(subject.match_person).to eq(person)
      end

      it 'sets matched_person_by' do
        subject.match_person
        expect(subject.matched_person_by).to eq('matched_person_by_contact_info')
      end
    end

    context 'given match strategy by_contact_info and matching email address' do
      before do
        import.update_attribute(:match_strategy, 'by_contact_info')
      end

      let!(:person) { FactoryGirl.create(:person, email: 'tim@timmorgan.org') }

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

      it 'returns the person' do
        expect(subject.match_person).to eq(person)
      end

      it 'sets matched_person_by' do
        subject.match_person
        expect(subject.matched_person_by).to eq('matched_person_by_contact_info')
      end
    end
  end

  describe '#match_family' do
    let(:import) do
      FactoryGirl.create(
        :import,
        mappings: {
          'family id'   => 'family_id',
          'family name' => 'family_name',
          'address'     => 'family_address1',
          'city'        => 'family_city',
          'state'       => 'family_state',
          'zip'         => 'family_zip',
          'phone'       => 'family_home_phone'
        }
      )
    end

    context 'given match strategy by_id_only and matching family' do
      before do
        import.update_attribute(:match_strategy, 'by_id_only')
      end

      let!(:family) { FactoryGirl.create(:family, name: 'James Smith', last_name: 'Smith') }

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'family id', value: family.id, sequence: 1 }
          ]
        )
      end

      it 'returns the family' do
        expect(subject.match_family).to eq(family)
      end

      it 'sets matched_family_by' do
        subject.match_family
        expect(subject.matched_family_by).to eq('matched_family_by_id')
      end
    end

    context 'given match strategy by_name and matching family found by id' do
      before do
        import.update_attribute(:match_strategy, 'by_name')
      end

      let!(:family1) { FactoryGirl.create(:family, name: 'James Smith', last_name: 'Smith') }
      let!(:family2) { FactoryGirl.create(:family, name: 'James Smith', last_name: 'Smith') }

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'family id',   value: family2.id,    sequence: 1 },
            { import: import, name: 'family name', value: 'James Smith', sequence: 2 }
          ]
        )
      end

      it 'returns the family matching by id' do
        expect(subject.match_family).to eq(family2)
      end

      it 'sets matched_family_by' do
        subject.match_family
        expect(subject.matched_family_by).to eq('matched_family_by_id')
      end
    end

    context 'given match strategy by_name and matching family' do
      before do
        import.update_attribute(:match_strategy, 'by_name')
      end

      let!(:family) { FactoryGirl.create(:family, name: 'James Smith', last_name: 'Smith') }

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'family name', value: 'James Smith', sequence: 1 }
          ]
        )
      end

      it 'returns the family' do
        expect(subject.match_family).to eq(family)
      end

      it 'sets matched_family_by' do
        subject.match_family
        expect(subject.matched_family_by).to eq('matched_family_by_name')
      end
    end

    context 'given match strategy by_contact_info and matching home phone' do
      before do
        import.update_attribute(:match_strategy, 'by_contact_info')
      end

      let!(:family) { FactoryGirl.create(:family, name: 'James Smith', last_name: 'Smith', home_phone: '9181234567') }

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'phone', value: '(918) 123-4567', sequence: 1 }
          ]
        )
      end

      it 'returns the family' do
        expect(subject.match_family).to eq(family)
      end

      it 'sets matched_family_by' do
        subject.match_family
        expect(subject.matched_family_by).to eq('matched_family_by_contact_info')
      end
    end

    context 'given match strategy by_contact_info and matching address' do
      before do
        import.update_attribute(:match_strategy, 'by_contact_info')
      end

      let!(:family) { FactoryGirl.create(:family, name: 'James Smith', last_name: 'Smith', address1: '123 N Main', city: 'Tulsa', state: 'OK', zip: '74120') }

      subject do
        FactoryGirl.create(
          :import_row,
          import: import,
          import_attributes_attributes: [
            { import: import, name: 'address', value: '123 N Main', sequence: 1 },
            { import: import, name: 'city',    value: 'Tulsa',      sequence: 2 },
            { import: import, name: 'state',   value: 'OK',         sequence: 3 },
            { import: import, name: 'zip',     value: '74120',      sequence: 4 }
          ]
        )
      end

      it 'returns the family' do
        expect(subject.match_family).to eq(family)
      end

      it 'sets matched_family_by' do
        subject.match_family
        expect(subject.matched_family_by).to eq('matched_family_by_contact_info')
      end
    end
  end
end
