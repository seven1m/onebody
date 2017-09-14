require_relative '../rails_helper'

describe Site, type: :model do
  describe 'callbacks' do
    context 'when the site is saved and Features/SSL setting is true' do
      around do |example|
        Setting.set_global('Features', 'SSL', true)
        Site.current.host = 'church.io'
        Site.current.save!
        example.run
        Site.current.host = 'example.com'
        Site.current.save!
        Setting.set_global('Features', 'SSL', false)
      end

      it 'updates the Site URL setting with https://' do
        expect(Setting.get(:url, :site)).to eq('https://church.io/')
      end
    end

    context 'when the site is saved and Features/SSL setting is false' do
      around do |example|
        Site.current.host = 'church.io'
        Site.current.save!
        example.run
        Site.current.host = 'example.com'
        Site.current.save!
      end

      it 'updates the Site URL setting with http://' do
        expect(Setting.get(:url, :site)).to eq('http://church.io/')
      end
    end
  end

  describe '#create_as_stream_item' do
    before do
      Site.current.create_as_stream_item
    end

    it 'creates a stream item' do
      expect(Site.current.reload.stream_item.attributes).to include(
        'title'  => 'One Church',
        'shared' => true
      )
    end
  end

  describe '#destroy' do
    let(:site) { Site.create!(name: 'Church.IO', host: 'church.io') }

    it 'raises an error' do
      expect { site.destroy }.to raise_error(StandardError)
    end
  end

  describe '#destroy_for_real' do
    let(:site) { Site.create!(name: 'Church.IO', host: 'church.io') }

    it 'deletes the site' do
      site.destroy_for_real
      expect { site.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
