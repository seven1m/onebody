class SettingsController < ApplicationController
  verify :method => :post, :only => :edit
  
  def index
    @settings = Setting.find_all_by_hidden(false, :order => 'section, name').group_by &:section
  end
  
  def edit
    Setting.find(:all).each do |setting|
      value = params[setting.id.to_s]
      value = value.split(/\n/) if value and setting.format == 'list'
      value = value == '' ? nil : value
      setting.update_attribute :value, value
    end
    Setting.load_settings
    flash[:notice] = 'Settings saved. You may need to restart the web server in order for some settings to take effect.'
    redirect_to settings_url
  end
end
