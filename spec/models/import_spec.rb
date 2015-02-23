require_relative '../rails_helper'

describe Import do
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

  describe 'before update' do
    subject { FactoryGirl.create(:import) }

    context 'given status is "parsed" and match strategy is chosen' do
      before do
        subject.status = :parsed
        subject.match_strategy = :by_name
        subject.save!
      end

      it 'changes the status to "matched"' do
        expect(subject.reload.status).to eq('matched')
      end
    end
  end
end
