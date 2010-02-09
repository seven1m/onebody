class Administration::SettingsController < ApplicationController
  
  before_filter :only_admins
  
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
    @lists['System']['Language'] = info.available_locales.invert
  end
  
  def batch
    Setting.find_all_by_site_id(Site.current.id).each do |setting|
      next if setting.hidden?
      value = params[setting.id.to_s]
      value = value.split(/\n/) if value and setting.format == 'list'
      value = value == '' ? nil : value
      value = value == 'true' if setting.format == 'boolean'
      setting.update_attributes! :value => value
    end
    reload_settings
    flash[:notice] = 'Settings saved.'
    redirect_to administration_settings_path
  end
  
  def reload
    reload_settings
    flash[:notice] = 'Settings reloaded.'
    redirect_to admin_path
  end
  
  private
  
    def only_admins
      unless @logged_in.super_admin?
        render :text => 'You must be a super administrator to modify settings.', :layout => true, :status => 401
        return false
      end
    end
  
    def reload_settings
      Site.current.update_attribute(:settings_changed_at, Time.now)
      expire_fragment(%r{views/})
    end
end
