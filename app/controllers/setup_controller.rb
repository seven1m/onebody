class SetupController < ApplicationController
  skip_before_filter :get_site, :authenticate_user
  before_filter :check_setup_env, :get_info
  
  layout "setup"
  
  def index
  end
  
  def precache
    @info.precache_info
    respond_to do |format|
      format.js { render(:update) { |p| p.redirect_to setup_dashboard_url } }
    end
  end
  
  def dashboard
    if PHONE_HOME_FOR_VERSION_INFO
      if @info.install_method == :git
        @up_to_date = @info.this_revision == @info.development_revision
      else
        @up_to_date = @info.this_version >= @info.development_version
      end
    else
      @up_to_date = nil
      @this_version = @info.this_version
    end
  end
  
  def environment
  end
  
  private
    def check_setup_env
      unless RAILS_ENV == 'setup'
        redirect_to '/'
        return false
      end
    end
    
    def get_info
      @info = (session[:one_body_info] ||= OneBodyInfo.new)
    end
end
