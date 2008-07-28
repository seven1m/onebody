class Setup::DatabaseController < Setup::BaseController
  verify :method => :post, :only => %w(migrate edit)
  
  def index
  end
  
  def load_fixtures
    logger.info `#{rake_cmd} onebody:load_sample_data RAILS_ENV=#{session[:setup_environment]}`
    flash[:notice] = 'Sample data loaded.'
    @info.reload
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
