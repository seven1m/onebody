class SetupController < ApplicationController
  skip_before_filter :get_site, :authenticate_user
  before_filter :check_setup_env, :check_auth, :get_info, :except => %w(not_local_or_secret_not_given authorize_ip)
  verify :method => :post, :only => %w(migrate_database edit_database edit_multisite delete_site edit_settings)
  
  layout "setup"
  
  def index
  end
  
  def precache
    @info.precache # also reload
    respond_to do |format|
      format.js { render(:update) { |p| p.redirect_to setup_dashboard_url } }
    end
  end
  
  def dashboard
    @sites = Site.find(:all, :order => 'name') rescue []
  end
  
  def environment
  end
  
  def database
  end
  
  def sites
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
  
  def delete_site
    if params[:sure]
      if @info.backup_database
        Site.find(params[:id]).destroy_for_sure
        flash[:notice] = 'Site deleted.'
      else
        flash[:warning] = 'Site was not deleted because backup failed.'
      end
    end
    redirect_to setup_sites_url
  end
  
  def edit_site
    @site = params[:id] ? Site.find(params[:id]) : Site.new
    if request.post?
      if @site.update_attributes params[:site]
        flash[:notice] = 'Site updated.'
        redirect_to setup_sites_url
      else
        flash[:warning] = @site.errors.full_messages.join('; ')
      end
    end
  end
  
  def backup_database
    if path = @info.backup_database
      flash[:notice] = "The database has been backed up to #{path}"
    else
      flash[:warning] = "There was an error backing up your database."
    end
    redirect_to setup_database_url
  end
  
  def load_fixtures
    if @info.backup_database
      logger.info `#{rake_cmd} db:fixtures:load RAILS_ENV=#{session[:setup_environment]}`
      flash[:notice] = 'Sample data loaded.'
      @info.reload
    else
      flash[:warning] = 'Sample data was not loaded because database backup failed.'
    end
    redirect_to setup_database_url
  end
  
  def edit_database
    if params[:test]
      if @info.test_database_config(params)
        message = 'Database connection successful!'
      else
        message = 'Error. Could not connect to database.'
      end
    else
      @info.edit_database(params)
      @info.precache
      message = 'New database config saved.'
      @redirect = true
    end
    respond_to do |format|
      format.html { flash[:notice] = message; redirect_to setup_database_url }
      format.js { render(:update) { |p| p.alert(message); p.redirect_to(setup_database_url) if @redirect } }
    end
  end
  
  def migrate_database
    logger.info `#{rake_cmd} db:migrate RAILS_ENV=#{session[:setup_environment]}`
    flash[:notice] = 'Database migrated.'
    @info.reload
    redirect_to setup_database_url
  end
  
  def change_environment
    if %w(production development).include? params[:environment]
      OneBodyInfo.setup_environment = session[:setup_environment] = params[:environment]
    end
    flash[:notice] = "Environment switched to #{session[:setup_environment]}."
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
  
  def cleanup
    File.delete(File.join(RAILS_ROOT, 'setup-authorized-ip'))
    File.delete(File.join(RAILS_ROOT, 'setup-secret'))
  end
  
  def settings
    @settings = Setting.find_all_by_site_id_and_hidden(
      params[:id],
      false,
      :order => 'section, name'
    ).group_by &:section
    render :template => 'settings/index'
  end
  
  def edit_settings
    (params[:id] ? Setting.find_all_by_site_id(params[:id]) : []) + \
    Setting.find_all_by_site_id_and_global(nil, true).each do |setting|
      next if setting.hidden?
      value = params[setting.id.to_s]
      value = value.split(/\n/) if value and setting.format == 'list'
      value = value == '' ? nil : value
      setting.update_attributes! :value => value
    end
    Setting.precache_settings(true)
    flash[:notice] = 'Settings saved.'
    redirect_to params[:id] ? setup_settings_url(:id => params[:id]) : setup_global_settings_url
  end
  
  def global_settings
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

  private
    def check_setup_env
      unless RAILS_ENV == 'setup'
        redirect_to '/'
        return false
      end
      OneBodyInfo.setup_environment = session[:setup_environment] ||= 'production'
    end
    
    def check_auth
      write_auth_file if request.remote_ip == '127.0.0.1'
      if File.exists?(auth_filename = File.join(RAILS_ROOT, 'setup-authorized-ip'))
        unless request.remote_ip == File.read(auth_filename)
          render :text => 'Only one IP can be authorized at a time. (Delete the setup-authorized-ip file to try again.)', :layout => true
          return false
        end
      else
        redirect_to :action => 'not_local_or_secret_not_given'
        return false
      end
    end
    
    def get_info
      @info = (session[:one_body_info] ||= OneBodyInfo.new)
    end
    
    def get_setup_secret
      File.read(File.join(RAILS_ROOT, 'setup-secret'))
    end
    
    def write_auth_file
      File.open(File.join(RAILS_ROOT, 'setup-authorized-ip'), 'w') do |file|
        file.write(request.remote_ip)
      end
    end
    
    def rake_cmd
      windows? ? 'rake.cmd' : 'rake'
    end
    
    def windows?
      RUBY_PLATFORM =~ /mswin32/
    end
end