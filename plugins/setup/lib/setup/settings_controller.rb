class Setup::SettingsController < Setup::BaseController
  verify :method => :post, :only => %w(edit)

  def index
    @settings = Setting.find_all_by_site_id_and_hidden(params[:site_id], false, :order => 'section, name').group_by &:section
    @lists = {'Appearance' => {}}
    info = OneBodyInfo.new
    @lists['Appearance']['Theme'] = info.themes
    @lists['Appearance']['Public Theme'] = info.themes + ['page:template']
    render :template => 'administration/settings/index'
  end
  
  def batch
    if params[:site_id].to_s.any?
      Setting.update_site_from_params(params[:site_id], params)
    else
      Setting.update_global_from_params(params)
    end
    flash[:notice] = 'Settings saved.'
    redirect_to administration_settings_path(:site_id => params[:site_id])
  end
end
