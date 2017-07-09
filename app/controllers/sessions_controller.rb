class SessionsController < ApplicationController
  skip_before_filter :authenticate_user
  before_filter :check_ssl, except: %w(destroy)
  before_filter :check_too_many_signin_failures, only: %w(create)

  helper_method :has_social_logins, :support_facebook_login

  layout 'signed_out'

  def show
    redirect_to new_session_path
  end

  # sign in form
  def new
    redirect_to(new_setup_path) unless Person.any?
  end

  def create_from_external_provider
    auth = request.env['omniauth.auth']
    @person = Person.where(
      provider: auth['provider'],
      uid: auth['uid'].to_s
    ).first || Signup.save_with_omniauth(auth)
    redirect_after_authentication
  end

  # sign in
  def create
    @person = Person.authenticate(params[:email], params[:password])
    redirect_after_authentication
  end

  # sign out
  def destroy
    reset_session
    redirect_to root_path
  end

  def has_social_logins
    support_facebook_login
  end

  def support_facebook_login
    !!Setting.get(:facebook, :app_id) && !!Setting.get(:facebook, :app_secret)
  end

  def setup_omniauth
    provider = params['provider']
    if provider == 'facebook' && support_facebook_login
      env['omniauth.strategy'].options[:client_id] = Setting.get(:facebook, :app_id)
      env['omniauth.strategy'].options[:client_secret] = Setting.get(:facebook, :app_secret)
      env['omniauth.strategy'].options[:scope] = 'email,user_posts'
    end
    render text: 'Setup complete.', status: 404
  end

  private

  STICKY_SESSION_LENGTH = 60.days

  def login_success
    setup_session!
    sticky_session!(STICKY_SESSION_LENGTH) if params[:remember_me]
    if @person.active?
      full_access_redirect
    else
      redirect_to @person
    end
  end

  STICKY_SESSION_LENGTH_FOR_CHECKIN = 365.days

  def login_success_for_checkin
    if @person.admin?(:manage_checkin)
      session[:checkin_logged_in_id] = @person.id
      sticky_session!(STICKY_SESSION_LENGTH_FOR_CHECKIN)
      if params[:from].present?
        redirect_to safe_redirect_path(params[:from])
      else
        redirect_to checkin_path
      end
    else
      redirect_to action: 'new'
    end
  end

  def full_access_redirect
    if params[:from].present?
      redirect_to safe_redirect_path(params[:from])
    else
      redirect_to stream_path
    end
  end

  def login_auth_fail
    if (person = find_person_by_email) && !person.has_password?
      flash.now[:error] = t('session.account_not_activated_html').html_safe
    else
      SigninFailure.create(email: params[:email], ip: request.remote_ip)
      flash.now[:error] = t('session.password_doesnt_match')
      @focus_password = true
    end
    render action: 'new'
  end

  def login_not_found
    if find_family_by_email
      flash[:warning] = t('session.email_found')
      redirect_to new_account_path(email: params[:email])
    else
      SigninFailure.create(email: params[:email], ip: request.remote_ip)
      flash.now[:error] = t('session.email_not_found')
      render action: 'new'
    end
  end

  def find_person_by_email
    Person.undeleted.where(email: params[:email].downcase).first
  end

  def find_family_by_email
    Family.undeleted.where(email: params[:email].downcase).first
  end

  def check_ssl
    return if request.ssl? || !Rails.env.production? || !Setting.get(:features, :ssl)
    redirect_to protocol: 'https://', from: params[:from]
    false
  end

  def check_too_many_signin_failures
    return if SigninFailure.matching(request).count <= Setting.get(:privacy, :max_sign_in_attempts).to_i
    render_message(
      t('session.max_sign_in_attempts'),
      callout: 'warning'
    )
    false
  end

  def setup_session!
    session[:logged_in_id] = @person.id
    session[:logged_in_name] = @person.name
    session[:ip_address] = request.remote_ip
  end

  def sticky_session!(length = 30.days)
    request.cookie_jar['_session_id'] = {
      value: request.cookie_jar['_session_id'],
      expires: length.from_now
    }
  end

  def redirect_after_authentication
    if @person && !@person.able_to_sign_in?
      redirect_to page_for_public_path('system/unauthorized')
    elsif @person
      if params[:for] == 'checkin'
        login_success_for_checkin
      else
        login_success
      end
    elsif @person == false
      login_auth_fail
    else
      login_not_found
    end
  end
end
