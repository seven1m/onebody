require 'rails_helper'
require 'stringio'

describe Import, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:person) }
    it { should validate_presence_of(:filename) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:importable_type).in_array(['Person']) }
  end

  describe '#status_at_least?' do
    context 'given argument is parsed' do
      context 'given status is pending' do
        before { subject.status = :pending }

        it 'returns false' do
          expect(subject.status_at_least?('parsed')).to eq(false)
        end
      end

      context 'given status is parsed' do
        before { subject.status = :parsed }

        it 'returns true' do
          expect(subject.status_at_least?('parsed')).to eq(true)
        end
      end

      context 'given status is complete' do
        before { subject.status = :complete }

        it 'returns true' do
          expect(subject.status_at_least?('parsed')).to eq(true)
        end
      end
    end
  end

  describe '#mappable_attributes' do
    subject { FactoryGirl.create(:import) }

    it 'returns array of attribute names' do
      expect(subject.mappable_attributes).to be_an(Array)
      expect(subject.mappable_attributes).to include(
        'first_name',
        'family_name'
      )
    end
  end

  describe '#parse_async' do
    subject { FactoryGirl.create(:import) }

    let(:file) { StringIO.new("first,last\nTim,Morgan\nJen,Morgan") }

    before do
      allow(ImportParserJob).to receive(:perform_later)
    end

    it 'updates the row count' do
      subject.parse_async(file: file, strategy_name: 'csv')
      expect(subject.reload.row_count).to eq(2)
    end
  end

  describe '#progress' do
    context 'given the status is parsed' do
      subject { FactoryGirl.create(:import, status: :parsed) }

      it 'returns 30' do
        expect(subject.progress).to eq(30)
      end
    end
  end
end
