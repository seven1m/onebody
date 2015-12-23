require_relative '../rails_helper'

describe Setting do
  context 'Field Types' do
    it "should return an array for settings of type 'list'" do
      Setting.set(1, 'System', 'Suffixes', ['Text', 'A Date'].join("\n"))
      expect(Setting.get(:system, :suffixes)).to eq(["Text", "A Date"])
      Setting.set(1, 'System', 'Suffixes', '')
    end

    it "should return an array for settings of type 'list', even if empty" do
      Setting.set(1, 'System', 'Suffixes', '')
      expect(Setting.get(:system, :suffixes)).to eq([])
    end
  end

  describe '.get' do
    context 'given a site without any settings' do
      let(:site) { Site.create!(name: 'Foo', host: 'church.io') }

      around do |example|
        Setting.where(site_id: site.id).delete_all
        Setting.precache_settings(true)
        SETTINGS[site.id] = nil
        Site.with_current(site) do
          example.run
        end
      end

      it 'creates the settings' do
        expect(Setting.get(:name, :site)).to eq('CHURCH.IO')
      end
    end

    context 'given a non-existent setting' do
      it 'returns nil' do
        expect(Setting.get(:foo, :bar)).to eq(nil)
      end
    end

    context 'given a non-existent setting and a default value argument' do
      it 'returns the default' do
        expect(Setting.get(:foo, :bar, 'default')).to eq('default')
      end
    end

    context 'given Site.current is not set' do
      around do |example|
        Site.with_current(nil) do
          example.run
        end
      end

      it 'raises an error' do
        expect { Setting.get(:foo, :bar) }.to raise_error(StandardError)
      end
    end
  end

  describe '.set' do
    context 'setting a non-existent value' do
      it 'raises an error' do
        expect {
          Setting.set(:foo, :bar, 'value')
        }.to raise_error(StandardError)
      end
    end
  end

  describe 'encryped field' do
    # (:stripe, :secret_key) is currently the only encrypted field

    context 'setting and getting a value' do
      it 'should return nil if get before set' do
        expect(Setting.get(:stripe, :secret_key)).to be_nil
      end
      
      it 'should set and get the field' do
        Setting.set(:stripe, :secret_key, 'password')
        expect(Setting.get(:stripe, :secret_key)).to eq 'password'
      end

      it 'should set the field to something not equal to value' do
        Setting.set(:stripe, :secret_key, 'password')
        setting = Setting.find_by section: 'Stripe', name: 'Secret Key'
        expect(setting.value_before_type_cast).not_to eq 'password'
      end
    end
  end
end
