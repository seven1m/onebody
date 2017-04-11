class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: -> { logged_in_from_api_key? }

  # these are prepended so they happen before verify_authenticity_token
  prepend_before_filter :authenticate_user_with_api_key
  prepend_before_filter :get_site

  include LoadAndAuthorizeResource

  LIMITED_ACCESS_AVAILABLE_ACTIONS = %w(
    groups/show groups/index
    memberships/*
    people/*
    pages/*
    sessions/*
    accounts/*
    privacies/*
    searches/*
    messages/new messages/create
    streams/show
  )

  layout :layout

  before_action :feature_enabled?
  before_action :authenticate_user
  before_action :update_last_seen_at
  before_action :setup_pusher

  helper_method :params_without_action

  def params_without_action
    params.except(:controller, :action)
  end

  protected

  def get_site
    if ENV['ONEBODY_SITE']
      Site.current = Site.where(id: ENV["ONEBODY_SITE"], active: true).first
    elsif Setting.get(:features, :multisite)
      Site.current = Site.where(host: request.host, active: true).first
    else
      Site.current = Site.where(id: 1).first || raise(t('application.no_default_site'))
    end
    if Site.current
      Setting.reload_if_stale
      OneBody.set_locale
      OneBody.set_time_zone
      OneBody.set_local_formats
    elsif site = Site.where(secondary_host: request.host, active: true).first
      redirect_to 'http://' + site.host
      return false
    elsif request.host =~ /^www\./
      redirect_to request.url.sub(/^(https?:\/\/)www\./, '\1')
      return false
    else
      render text: t('application.no_site_configured', host: request.host), status: 404
      return false
    end
  end

  # used by some anonymous controller actions to see if someone is logged in
  # (without redirecting if they are not)
  def get_user
    if id = session[:logged_in_id]
      Person.logged_in = @logged_in = Person.where(id: id).first
    end
  end

  def current_site
    Site.current
  end

  def current_user
    @logged_in
  end
  helper_method :current_user

  def authenticate_user # default
    authenticate_user_with_session unless logged_in_from_api_key?
  end

  def authenticate_user_for_checkin
    id = session[:checkin_logged_in_id]
    @checkin_logged_in = Person.find(id) if id
    return if @checkin_logged_in && @checkin_logged_in.admin?(:manage_checkin)
    redirect_to new_session_path(for: 'checkin', from: request.fullpath)
    return false
  end

  def authenticate_user_with_session
    if id = session[:logged_in_id]
      unless person = Person.where(id: id).first
        session[:logged_in_id] = nil
        redirect_to new_session_path
        return false
      end
      unless person.able_to_sign_in?
        session[:logged_in_id] = nil
        redirect_to page_for_public_path('system/bad_status')
        return false
      end
      Person.logged_in = @logged_in = person
      check_full_access
      if Site.current.id != @logged_in.site_id
        session[:logged_in_id] = nil
        redirect_to new_session_path
        return false
      end
    else
      redirect_to new_session_path(from: request.fullpath)
      return false
    end
  end

  def authenticate_user_with_code_or_session
    Person.logged_in = @logged_in = nil
    unless params[:code] and Person.logged_in = @logged_in = Person.undeleted.where(feed_code: params[:code], deleted: false).first
      authenticate_user_with_session
    end
  end

  def authenticate_user_with_api_key
    authenticate_with_http_basic do |email, api_key|
      if email.present? and
        api_key.to_s.length == 50 and
        person = Person.undeleted.where(email: email, api_key: api_key).first and
        person.super_admin?
        Person.logged_in = @logged_in = person
        @logged_in_from_api_key = true
      end
    end
  end

  def update_last_seen_at
    @logged_in.update_last_seen_at if @logged_in
  end

  def check_full_access
    if @logged_in && @logged_in.pending?
      unless LIMITED_ACCESS_AVAILABLE_ACTIONS.include?("#{params[:controller]}/#{params[:action]}") or \
             LIMITED_ACCESS_AVAILABLE_ACTIONS.include?("#{params[:controller]}/*")
        render text: t('people.limited_access_denied'), layout: true, status: 401
        return false
      end
    end
  end

  def authority_forbidden(error)
    Authority.logger.warn(error.message)
    render text: I18n.t('not_authorized'), layout: true, status: :forbidden
  end

  rescue_from 'LoadAndAuthorizeResource::AccessDenied', 'LoadAndAuthorizeResource::ParameterMissing' do |e|
    render text: I18n.t('not_authorized'), layout: true, status: :forbidden
  end

  rescue_from 'EmailConnectionError' do |e|
    render 'errors/email_connection_error'
  end

  def me?
    @logged_in and @person and @logged_in == @person
  end

  def redirect_back(fallback=nil)
    if params[:from]
      redirect_to safe_redirect_path(params[:from])
    elsif request.env["HTTP_REFERER"]
      redirect_to safe_redirect_path(request.env["HTTP_REFERER"])
    elsif fallback
      redirect_to fallback
    else
      redirect_to people_path
    end
    return false # in case you want to halt action
  end

  def safe_redirect_path(url)
    uri = URI.parse(url)
    uri.path.tap do |path|
      path << '?' + uri.query if uri.query
    end
  end

  def add_errors_to_flash(record)
    flash[:warning] = record.errors.values.join('; ')
  end

  def only_admins
    unless @logged_in.admin?
      render text: t('only_admins'), layout: true, status: 401
      return false
    end
  end

  def logged_in_from_api_key?
    !!@logged_in_from_api_key
  end

  def feature_enabled?
    true
  end

  def can_export?
    @logged_in and @logged_in.admin?(:export_data) and Site.current.import_export_enabled?
  end

  def layout
    if @logged_in
      'default'
    else
      'signed_out'
    end
  end

  def setup_pusher
    Pusher.app_id = Setting.get(:pusher, :app_id)
    Pusher.key    = Setting.get(:pusher, :app_key)
    Pusher.secret = Setting.get(:pusher, :secret)
    Pusher.scheme = Setting.get(:pusher, :api_scheme)
    Pusher.host   = Setting.get(:pusher, :api_host)
    Pusher.port   = Setting.get(:pusher, :api_port).to_i
  end

  def render_message(message, layout: true, callout: nil, status: 200)
    @narrow = true
    if callout
      message = view_context.content_tag(:div, class: "callout callout-#{callout}") do
        message.html_safe
      end
    end
    render text: message, layout: layout, status: status
  end
end
