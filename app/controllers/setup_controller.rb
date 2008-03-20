class SetupController < ApplicationController
  skip_before_filter :get_site, :authenticate_user
  before_filter :check_setup_env
  
  layout "setup"
  
  def index
    if File.exists?(File.join(RAILS_ROOT, 'installed-from-gem')) 
      @install_method = :gem
    elsif File.exists?(File.join(RAILS_ROOT, '.git'))
      @install_method = :git
    else
      @install_method = :manual
    end
  end
  
  def current_version
    current_version = open('http://beonebody.org/releases/CURRENT').read.strip
    respond_to do |format|
      format.js { render(:update) { |p| p.replace_html :current_version, current_version } }
    end
  end
  
  private
    def check_setup_env
      unless RAILS_ENV == 'setup'
        redirect_to '/'
        return false
      end
    end
end
