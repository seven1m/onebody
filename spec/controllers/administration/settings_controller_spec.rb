require 'rails_helper'

describe Administration::SettingsController, type: :controller do
  let(:admin) { FactoryGirl.create(:person, :super_admin) }

  describe '#index' do
    before do
      get :index,
          session: { logged_in_id: admin.id }
    end

    render_views

    it 'renders the index template' do
      expect(response).to render_template(:index)
    end
  end

  describe '#batch' do
    let(:suffixes_setting) { Site.current.settings.where(name: 'Suffixes').first! }

    context 'given valid settings' do
      before do
        put :batch,
            params: {
              'hostname' => 'church.io',
              suffixes_setting.id.to_s => "Jr.\r\nSr."
            },
            session: { logged_in_id: admin.id }
      end

      after do
        Site.current.update_attributes!(host: 'example.com')
      end

      it 'redirects to the index' do
        expect(response).to redirect_to(administration_settings_path)
      end

      it 'updates settings' do
        expect(Site.current.reload.host).to eq('church.io')
        expect(Setting.get(:system, :suffixes)).to eq(%w(Jr. Sr.))
      end
    end

    context 'given invalid settings' do
      before do
        put :batch,
            params: {
              'hostname' => 'http://www.example.com'
            },
            session: { logged_in_id: admin.id }
      end

      after do
        Site.current.update_attributes!(host: 'example.com')
      end

      it 'adds errors to the flash and redirects' do
        expect(flash[:warning]).to match(/www/)
        expect(response).to redirect_to(administration_settings_path)
      end
    end
  end

  describe '#reload' do
    before do
      Timecop.freeze(Time.now)
      put :reload,
          session: { logged_in_id: admin.id }
    end

    after do
      Timecop.return
    end

    it 'updates the settings_changed_at timestamp and redirects' do
      expect(Site.current.reload.settings_changed_at).to be_within(1).of(Time.now)
      expect(response).to redirect_to(admin_path)
    end
  end
end
