class SessionsController < ApplicationController
  skip_before_filter :authenticate_user
  before_filter :check_ssl, except: %w(destroy)
  before_filter :check_too_many_signin_failures, only: %w(create)

  def show
    redirect_to new_session_path
  end

  # sign in form
  def new
    if not Person.any?
      redirect_to new_setup_path
    end
  end

  # sign in
  def create
    params[:email].downcase!
    if @person = Person.authenticate(params[:email], params[:password])
      unless @person.can_sign_in?
        redirect_to page_for_public_path('system/unauthorized')
        return
      end
      setup_session!
      if params[:from].to_s.any?
        redirect_to URI.parse(params[:from]).path
      elsif @person.full_access?
        redirect_to stream_path
      else
        redirect_to @person
      end
    elsif @person == false # person found, but not authenticated
      if p = Person.undeleted.where(email: params[:email]).first and p.password_hash.nil? and p.encrypted_password.nil?
        flash[:warning] = t('session.account_not_activated_html').html_safe
      else
        flash[:warning] = t('session.password_doesnt_match')
        SigninFailure.create(email: params[:email], ip: request.remote_ip)
      end
      render action: 'new'
      flash.clear
    else # person not found
      if Family.undeleted.where(email: params[:email]).first
        flash[:warning] = t('session.email_found')
        redirect_to new_account_path(email: params[:email])
      else
        flash[:warning] = t('session.email_not_found_try_another')
        render action: 'new'
        flash.clear
      end
    end
  end

  # sign out
  def destroy
    reset_session
    redirect_to new_session_path
  end

  private
    def check_ssl
      unless request.ssl? or !Rails.env.production? or !Setting.get(:features, :ssl)
        redirect_to protocol: 'https://', from: params[:from]
        return false
      end
    end

    def check_too_many_signin_failures
      if SigninFailure.matching(request).count > Setting.get(:privacy, :max_sign_in_attempts).to_i
        render text: t('session.max_sign_in_attempts'), layout: true
        return false
      end
    end

    def setup_session!
      session[:logged_in_id] = @person.id
      session[:logged_in_name] = @person.name
      session[:ip_address] = request.remote_ip
    end

end
