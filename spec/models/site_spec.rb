require_relative '../rails_helper'

describe Site do
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
end
