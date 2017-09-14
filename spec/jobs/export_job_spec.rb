require 'rails_helper'

describe ExportJob do
  let(:person) { FactoryGirl.create(:person) }

  describe '#perform' do
    context 'when requesting groups xml' do
      let!(:group) { FactoryGirl.create(:group, name: 'Foo') }

      before do
        subject.perform(Site.current, 'groups', 'xml', person.id)
      end

      it 'exports groups to an xml file' do
        file = GeneratedFile.last
        expect(file.file).to be
        expect(File.read(file.file.path)).to match(
          %r{<name>Foo</name>}
        )
      end
    end

    context 'when requesting groups csv' do
      let!(:group) { FactoryGirl.create(:group, name: 'Foo') }

      before do
        subject.perform(Site.current, 'groups', 'csv', person.id)
      end

      it 'exports groups to a csv file' do
        file = GeneratedFile.last
        expect(file.file).to be
        expect(File.read(file.file.path)).to match(
          /name,description.*Foo/m
        )
      end
    end

    context 'when requesting people xml' do
      before do
        subject.perform(Site.current, 'people', 'xml', person.id)
      end

      it 'exports people to an xml file' do
        file = GeneratedFile.last
        expect(file.file).to be
        expect(File.read(file.file.path)).to match(
          %r{<first_name>John</first_name>}
        )
      end
    end

    context 'when requesting people csv' do
      before do
        subject.perform(Site.current, 'people', 'csv', person.id)
      end

      it 'exports people to a csv file' do
        file = GeneratedFile.last
        expect(file.file).to be
        expect(File.read(file.file.path)).to match(
          /first_name,last_name.*John,Smith/m
        )
      end
    end
  end
end
