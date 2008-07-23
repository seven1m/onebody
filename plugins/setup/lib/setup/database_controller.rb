class Setup::DatabaseController < Setup::BaseController
  verify :method => :post, :only => %w(migrate edit)
  
  def index
  end
  
  def backup
    if path = @info.backup_database
      flash[:notice] = "The database has been backed up to #{path}"
    else
      flash[:warning] = "There was an error backing up your database."
    end
    redirect_to setup_database_url
  end
  
  def load_fixtures
    if @info.backup_database
      logger.info `#{rake_cmd} onebody:load_sample_data RAILS_ENV=#{session[:setup_environment]}`
      flash[:notice] = 'Sample data loaded.'
      @info.reload
    else
      flash[:warning] = 'Sample data was not loaded because database backup failed.'
    end
    redirect_to setup_database_url
  end
  
  def edit
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
  
  def migrate
    logger.info `#{rake_cmd} db:migrate RAILS_ENV=#{session[:setup_environment]}`
    flash[:notice] = 'Database migrated.'
    @info.reload
    redirect_to setup_database_url
  end
end
