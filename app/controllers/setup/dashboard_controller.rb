class Setup::DashboardController < Setup::BaseController
  
  def index
    begin
      @sites = Site.find(:all, :order => 'name')
    rescue
      @sites = []
    end
  end
  
  def environment
  end
  
  def change_environment
    if %w(production development).include? params[:environment]
      OneBodyInfo.setup_environment = session[:setup_environment] = params[:environment]
    end
    flash[:notice] = "Environment switched to #{session[:setup_environment]}."
    @info.reload
    redirect_to setup_url
  end
  
  def not_local_or_secret_not_given
    @secret_file_path = File.expand_path(File.join(RAILS_ROOT, 'setup-secret'))
  end
  
  def authorize_ip
    if params[:setup_secret] == File.read(File.join(RAILS_ROOT, 'setup-secret'))
      write_auth_file
      redirect_to setup_url
    else
      File.open(File.join(RAILS_ROOT, 'setup-secret'), 'w') { |f| f.write random_chars(50) } # regenerate
      flash[:notice] = 'That secret is incorrect. Please try again.'
      redirect_to :action => 'not_local_or_secret_not_given'
    end
  end
end