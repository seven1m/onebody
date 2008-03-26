class Setup::SettingsController < SetupBaseController
  verify :method => :post, :only => %w(edit)

  def view
    @settings = Setting.find_all_by_site_id_and_hidden(
      params[:id],
      false,
      :order => 'section, name'
    ).group_by &:section
    render :template => 'settings/index'
  end
  
  def edit
    if params[:id]
      Setting.update_site_from_params(params[:id], params)
    else
      Setting.update_global_from_params(params)
    end
    flash[:notice] = 'Settings saved.'
    redirect_to params[:id] ? setup_settings_url(:id => params[:id]) : setup_global_settings_url
  end
  
  def global
    begin
      @info.connect_to_database(@info.database_config)
      @settings = Setting.find_all_by_site_id_and_hidden(
        nil,
        false,
        :order => 'section, name'
      ).group_by &:section
    rescue
      render :text => 'Could not establish database connection or database not up-to-date.', :layout => true
    else
      render :template => 'settings/index'
    end
  end
end
