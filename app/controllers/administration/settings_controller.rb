class Administration::SettingsController < ApplicationController
  
  def index
    @settings = Setting.find_all_by_site_id_and_hidden(
      Site.current.id,
      false,
      :order => 'section, name'
    ).group_by &:section
    @lists = {'Appearance' => {}, 'System' => {}}
    info = OneBodyInfo.new
    @lists['Appearance']['Theme'] = info.themes
    @lists['Appearance']['Public Theme'] = info.themes + ['page:template']
    @lists['System']['Time Zone'] = ActiveSupport::TimeZone.all.map { |z| [z.to_s, z.name] }
  end
  
  def batch
    Setting.find_all_by_site_id(Site.current.id).each do |setting|
      next if setting.hidden?
      value = params[setting.id.to_s]
      value = value.split(/\n/) if value and setting.format == 'list'
      value = value == '' ? nil : value
      setting.update_attributes! :value => value
      if setting.section == 'Appearance' and setting.name == 'Theme' and value == 'custom'
        FileUtils.mkdir_p("#{Rails.root}/themes/custom/site#{Site.current.id}")
      end
    end
    Setting.precache_settings(true)
    expire_fragment(%r{views/})
    flash[:notice] = 'Settings saved.'
    redirect_to administration_settings_path
  end
end
