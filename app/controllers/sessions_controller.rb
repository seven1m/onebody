class SessionsController < ApplicationController
  filter_parameter_logging :password
  
  skip_before_filter :authenticate_user
  before_filter :check_ssl, :except => %w(destroy)
  
  # sign in form
  def new
    flash[:warning] = 'There are no users in the system.' unless Person.count > 0
    @salt = session_salt unless Setting.get(:features, :ssl)
  end
  
  # sign in
  def create
    @salt = session_salt unless Setting.get(:features, :ssl)
    if person = Person.authenticate(params[:email], Setting.get(:features, :ssl) ? params[:password] : params[:password_encrypted], :encrypted => !Setting.get(:features, :ssl), :salt => @salt)
      unless person.can_sign_in?
        redirect_to help_path('unauthorized')
        return
      end
      session[:logged_in_id] = person.id
      session[:logged_in_name] = person.first_name + ' ' + person.last_name
      session[:ip_address] = request.remote_ip
      flash[:notice] = "Welcome, #{person.first_name}."
      if params[:from]
        redirect_to 'http://' + request.host + ([80, 443].include?(request.port) ? '' : ":#{request.port}") + params[:from]
      else
        redirect_to person
      end
    elsif person == nil
      if family = Family.find_by_email(params[:email])
        flash[:warning] = 'That email address was found, but you must verify it before you can sign in.'
        redirect_to new_account_path(:email => params[:email])
      else
        flash[:warning] = 'That email address cannot be found in our system. Please try another email.'
        render :action => 'new'
      end
    else
      flash[:warning] = "The password you entered doesn't match our records. Please try again."
      render :action => 'new'
    end
  end
  
  # sign out
  def destroy
    session[:logged_in_id] = nil
    redirect_to new_session_path
  end
  
  private
    def check_ssl
      unless request.ssl? or RAILS_ENV != 'production' or !Setting.get(:features, :ssl)
        redirect_to :protocol => 'https://', :from => params[:from]
        return
      end
    end
    
    def session_salt
      unless session[:salt] and session[:salt_generated] > 5.minutes.ago
        session[:salt] = (0..25).inject('') { |r, i| r << rand(93) + 33 }
        session[:salt_generated] = Time.now
      end
      session[:salt]
    end
  
end
