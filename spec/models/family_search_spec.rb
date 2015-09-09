require_relative '../rails_helper'

describe FamilySearch do
  let(:other_family) { FactoryGirl.create(:family, name: 'Jack Jones', last_name: 'Jones') }
  let(:other_person) { FactoryGirl.create(:person, first_name: 'Jack', last_name: 'Jones', family: other_family) }

  let!(:user) { FactoryGirl.create(:person) }

  before { Person.logged_in = user }

  it 'does not return deleted families' do
    @deleted = FactoryGirl.create(:family, deleted: true)
    expect(FamilySearch.new.results).to_not include(@deleted)
  end

  context 'search for families' do
    subject { FamilySearch.new }

    it 'returns matching families by name' do
      subject.name = 'Smith'
      expect(subject.results).to eq([user.family])
    end

    it 'returns matching families by barcode id' do
      user.family.barcode_id = '1234567890'
      user.family.save!
      subject.barcode_id = '1234567890'
      expect(subject.results).to eq([user.family])
    end

    it 'returns matching families by alternate barcode id' do
      user.family.alternate_barcode_id = '1234567890'
      user.family.save!
      subject.barcode_id = '1234567890'
      expect(subject.results).to eq([user.family])
    end
  end
end
