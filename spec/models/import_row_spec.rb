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
end
