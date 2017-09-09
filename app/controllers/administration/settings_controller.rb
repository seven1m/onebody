class Administration::SettingsController < ApplicationController
  before_action :only_admins

  def index
    @settings = {}
    our_settings.each do |setting|
      @settings[setting.section] ||= {}
      @settings[setting.section][setting['name']] = setting
    end
    @timezones = ActiveSupport::TimeZone.all.map { |z| [z.to_s, z.name] }
  end

  def batch
    if update_site
      update_settings
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

  def update_site
    Site.current.host = params[:hostname] if params[:hostname]
    Site.current.email_host = params[:email_host] if params[:email_host]
    Site.current.save
  end

  def update_settings
    our_settings.each do |setting|
      next unless (value = params[setting.id.to_s])
      value = value.presence
      value = value == 'true' if setting.format == 'boolean'
      setting.update_attributes!(value: value)
    end
    reload_settings
  end

  def our_settings
    Setting.where(hidden: false).where('site_id = ? or global = ?', Site.current.id, true).order('section, name')
  end

  def only_admins
    return if @logged_in.super_admin?
    render html: t('admin.must_be_superadmin'), layout: true, status: 401
    false
  end

  def reload_settings
    Site.current.update_attribute(:settings_changed_at, Time.now)
  end
end
