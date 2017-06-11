require_relative '../rails_helper'

describe Version do
  describe '.from_string' do
    context 'given 3.4.0' do
      let(:version) { Version.from_string('3.4.0') }

      it 'sets major to 3' do
        expect(version.major).to eq('3')
      end

      it 'sets minor to 4' do
        expect(version.minor).to eq('4')
      end

      it 'sets patch to 0' do
        expect(version.patch).to eq('0')
      end

      it 'sets special to nil' do
        expect(version.special).to be_nil
      end
    end

    context 'given 3.4.0-pre' do
      let(:version) { Version.from_string('3.4.0-pre') }

      it 'sets special to "pre"' do
        expect(version.special).to eq('pre')
      end
    end
  end

  describe '<=>' do
    context 'given 3.4.0 and 3.4.0-pre' do
      let(:version) { Version.from_string('3.4.0') }

      it 'returns +1' do
        expect(version <=> Version.from_string('3.4.0-pre')).to eq(1)
      end
    end

    context 'given 3.4.0 and 3.5.0-pre' do
      let(:version) { Version.from_string('3.4.0') }

      it 'returns -1' do
        expect(version <=> Version.from_string('3.5.0-pre')).to eq(-1)
      end
    end

    context 'given 3.4.0 and 3.5.0' do
      let(:version) { Version.from_string('3.4.0') }

      it 'returns -1' do
        expect(version <=> Version.from_string('3.5.0')).to eq(-1)
      end
    end
  end

  describe '#to_s' do
    context 'given 3.4.0' do
      let(:version) { Version.from_string('3.4.0') }

      it 'returns 3.4.0' do
        expect(version.to_s).to eq('3.4.0')
      end
    end

    context 'given 3.4.0-pre' do
      let(:version) { Version.from_string('3.4.0-pre') }

      it 'returns 3.4.0-pre' do
        expect(version.to_s).to eq('3.4.0-pre')
      end
    end
  end
end
