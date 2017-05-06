require 'rails_helper'

describe PhoneNumberPresenter do
  describe '#formatted' do
    context 'with dashes' do
      subject do
        described_class.new('1234567890', 'ddd-ddd-dddd')
      end

      specify do
        expect(subject.formatted).to eq(
          '123-456-7890'
        )
      end
    end

    context 'with area code parens' do
      subject do
        described_class.new('1234567890', '(ddd) ddd-dddd')
      end

      specify do
        expect(subject.formatted).to eq(
          '(123) 456-7890'
        )
      end
    end

    context 'given too few digits' do
      subject do
        described_class.new('123456789', '(ddd) ddd-dddd')
      end

      specify do
        expect(subject.formatted).to eq(
          '(123) 456-789'
        )
      end
    end

    context 'given too many digits' do
      subject do
        described_class.new('12345678901', '(ddd) ddd-dddd')
      end

      specify do
        expect(subject.formatted).to eq(
          '(123) 456-7890 1'
        )
      end
    end

    context 'given a blank string' do
      it 'returns a blank string' do
        expect(described_class.new('', '(ddd) ddd-dddd').formatted).to eq('')
      end
    end

    context 'given nil' do
      it 'returns a blank string' do
        expect(described_class.new(nil, '(ddd) ddd-dddd').formatted).to eq('')
      end
    end
  end
end
