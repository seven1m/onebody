class Setup::SitesController < Setup::BaseController
  verify :method => :post, :only => %w(edit_multisite delete)

  def index
    begin
      @info.connect_to_database(@info.database_config)
      @sites = Site.find(:all, :order => 'name')
      @new_site = Site.new
    rescue
      render :text => 'Could not establish database connection or database not up-to-date.', :layout => true
    end
  end
  
  def edit_multisite
    Setting.set_global('Features', 'Multisite', params[:multisite] == 'true')
    flash[:notice] = 'Multisite feature changed.'
    redirect_to setup_sites_url
  end
  
  def delete
    if params[:sure]
      Site.find(params[:id]).destroy_for_sure
      flash[:notice] = 'Site deleted.'
    end
    redirect_to setup_sites_url
  end
  
  def edit
    @site = params[:id] ? Site.find(params[:id]) : Site.new
    if request.post?
      if @site.update_attributes params[:site]
        flash[:notice] = 'Site updated.'
        redirect_to setup_sites_url
      else
        add_errors_to_flash(@site)
      end
    end
  end
end
