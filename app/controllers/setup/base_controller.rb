class Setup::BaseController < ActionController::Base
  skip_before_filter :get_site, :authenticate_user
  before_filter :check_setup_env, :check_auth, :get_info, :except => %w(not_local_or_secret_not_given authorize_ip)
  
  layout "setup"
  
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
        redirect_to setup_not_authorized_url
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
