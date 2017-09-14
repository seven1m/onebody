require_relative '../rails_helper'

describe ImportPreview, type: :model do
  let(:import) do
    FactoryGirl.create(
      :import,
      status: 'previewing',
      match_strategy: 'by_name',
      mappings: {
        'id'        => 'id',
        'first'     => 'first_name',
        'last'      => 'last_name',
        'fam_id'    => 'family_id',
        'fam_name'  => 'family_name',
        'fam_lname' => 'family_last_name',
        'phone'     => 'family_home_phone',
        'email'     => 'email'
      }
    )
  end

  subject { ImportPreview.new(import) }

  def create_row(attrs)
    FactoryGirl.create(
      :import_row,
      import: import,
      status: :parsed,
      import_attributes_attributes: attrs.each_with_index.map do |(name, value), index|
        { import: import, name: name.to_s, value: value, sequence: index }
      end
    )
  end

  describe '#preview' do
    let(:family)  { FactoryGirl.create(:family, name: 'George Morgan', last_name: 'Morgan', home_phone: nil) }
    let!(:person) { FactoryGirl.create(:person, first_name: 'George', last_name: 'Morgan', email: nil, family: family) }
    let!(:row1)   { create_row(first: 'John', last: 'Jones', fam_name: 'John & Jane Jones') }
    let!(:row2)   { create_row(first: 'Jane', last: 'Jones', fam_name: 'John & Jane Jones') }
    let!(:row3)   { create_row(first: 'George', last: 'Morgan', email: 'a@new.com', fam_name: 'George Morgan', phone: '1234567890') }

    it 'updates the import status' do
      expect { subject.preview }.to change(import, :status).to('previewed')
    end

    it 'does not set the completed_at time' do
      subject.execute
      expect(import.completed_at).to be_nil
    end

    it 'updates the status of the rows' do
      subject.preview
      expect(row1.reload.attributes).to include(
        'status' => 'previewed'
      )
    end

    it 'does not actually create person or family records' do
      expect do
        subject.preview
      end.not_to change { [Person.count, Family.count] }
      expect(row1.reload.attributes).to include(
        'created_person' => true,
        'created_family' => true,
        'person_id' => nil,
        'family_id' => nil
      )
    end

    it 'caches records to be created so they do not get marked as created again' do
      subject.preview
      expect(row2.reload.attributes).to include(
        'created_person'   => true,
        'created_family'   => false,
        'person_id'        => nil,
        'family_id'        => nil,
        'attribute_errors' => {}
      )
    end

    it 'does not actually update person or family records' do
      subject.preview
      expect(person.reload.email).to be_nil
      expect(family.reload.home_phone).to be_nil
      expect(row3.reload.attributes).to include(
        'updated_person' => true,
        'updated_family' => true,
        'person_id' => person.id,
        'family_id' => family.id
      )
    end

    it 'records what attributes changed' do
      subject.preview
      expect(row3.reload.attribute_changes).to eq(
        'person' => {
          'email' => [nil, 'a@new.com']
        },
        'family' => {
          'home_phone' => [nil, '1234567890']
        }
      )
    end
  end
end
