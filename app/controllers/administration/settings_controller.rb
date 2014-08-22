class Administration::SettingsController < ApplicationController

  before_filter :only_admins

  def index
    @settings = {}
    our_settings.each do |setting|
      @settings[setting.section] ||= {}
      @settings[setting.section][setting['name']] = setting
    end
    @timezones = ActiveSupport::TimeZone.all.map { |z| [z.to_s, z.name] }
  end

  def batch
    Site.current.host = params[:hostname] if params[:hostname]
    Site.current.email_host = params[:email_host] if params[:email_host]
    if Site.current.save
      our_settings.each do |setting|
        if value = params[setting.id.to_s]
          value = value == '' ? nil : value
          value = value == 'true' if setting.format == 'boolean'
          setting.update_attributes! value: value
        end
      end
      reload_settings
      flash[:notice] = t('application.settings_saved')
    else
      add_errors_to_flash(Site.current)
    end
    redirect_to administration_settings_path
  end

  def reload
    reload_settings
    flash[:notice] = t('application.settings_reloaded')
    redirect_to admin_path
  end

  private

  def our_settings
    Setting.where(hidden: false).where("site_id = ? or global = ?", Site.current.id, true).order('section, name')
  end

  def only_admins
    unless @logged_in.super_admin?
      render text: t('admin.must_be_superadmin'), layout: true, status: 401
      return false
    end
  end

  def reload_settings
    Site.current.update_attribute(:settings_changed_at, Time.now)
  end
end
