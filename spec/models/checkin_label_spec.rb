require 'rails_helper'

describe CheckinLabel, type: :model do
  describe '#xml' do
    context 'given raw xml' do
      let(:xml) { '<?xml version="1.0" encoding="utf-8"?><foo/>' }

      subject do
        FactoryGirl.build(:checkin_label, xml: xml)
      end

      it 'returns the xml' do
        expect(subject.xml).to eq(xml)
      end
    end

    context 'given file reference' do
      let(:xml) { '<file src="default.xml"/>' }

      subject do
        FactoryGirl.build(:checkin_label, xml: xml)
      end

      it 'returns the xml from the file' do
        xml = File.read(Rails.root.join('db/checkin/labels/default.xml'))
        expect(subject.xml).to eq(xml)
      end
    end

    context 'given file reference outside bounds' do
      let(:xml) { '<file src="../../../config/secrets.yml"/>' }

      subject do
        FactoryGirl.build(:checkin_label, xml: xml)
      end

      it 'raises an error' do
        expect { subject.xml }.to raise_error(CheckinLabel::InvalidCheckinLabelPath)
      end
    end

    context 'given file reference with absolute path' do
      let(:xml) { '<file src="/Users/timmorgan/pp/onebody/config/secrets.yml"/>' }

      subject do
        FactoryGirl.build(:checkin_label, xml: xml)
      end

      it 'raises an error' do
        expect { subject.xml }.to raise_error(CheckinLabel::InvalidCheckinLabelPath)
      end
    end

    context 'given file reference to non-existent file' do
      let(:xml) { '<file src="nonexistent.xml"/>' }

      subject do
        FactoryGirl.build(:checkin_label, xml: xml)
      end

      it 'raises an error' do
        expect { subject.xml }.to raise_error(CheckinLabel::InvalidCheckinLabelPath)
      end
    end
  end

  describe '#xml_file=' do
    let(:path) { Rails.root.join('db/checkin/labels/default.xml') }

    subject { FactoryGirl.build(:checkin_label, xml_file: Rack::Test::UploadedFile.new(path, 'application/xml', true)) }

    it 'sets the xml' do
      expect(subject.xml).to eq(File.read(path))
    end
  end
end
