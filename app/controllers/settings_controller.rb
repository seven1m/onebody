class SettingsController < ApplicationController
  verify :method => :post, :only => :edit
  
  def index
    @settings = Setting.find_all_by_hidden(false, :order => 'section, name').group_by &:section
  end
  
  def edit
    Setting.find(:all).each do |setting|
      value = params[setting.id]
      value = value.split(/\n/) if value and setting.format == 'list'
      setting.update_attribute :value, value
    end
    flash[:notice] = 'Settings saved.'
    redirect_to settings_url
  end
end
