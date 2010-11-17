class Administration::SettingsController < ApplicationController

  before_filter :only_admins

  def index
    @settings = {}
    Setting.find_all_by_site_id_and_hidden(
      Site.current.id,
      false,
      :order => 'section, name'
    ).each do |setting|
      @settings[setting.section] ||= {}
      @settings[setting.section][setting['name']] = setting
    end
    @timezones = ActiveSupport::TimeZone.all.map { |z| [z.to_s, z.name] }
    info = OneBodyInfo.new
    @langs = info.available_locales.invert
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
    flash[:notice] = t('application.settings_saved')
    redirect_to administration_settings_path
  end

  def reload
    reload_settings
    flash[:notice] = t('application.settings_reloaded')
    redirect_to admin_path
  end

  private

    def only_admins
      unless @logged_in.super_admin?
        render :text => t('admin.must_be_superadmin'), :layout => true, :status => 401
        return false
      end
    end

    def reload_settings
      Site.current.update_attribute(:settings_changed_at, Time.now)
      expire_fragment(%r{views/})
    end
end
