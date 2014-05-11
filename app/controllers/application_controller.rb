class ApplicationController < ActionController::Base
  protect_from_forgery

  include LoadAndAuthorizeResource

  LIMITED_ACCESS_AVAILABLE_ACTIONS = %w(groups/show groups/index people/* pages/* sessions/* accounts/*)

  layout 'default'

  before_filter :get_site
  before_filter :feature_enabled?
  before_filter :authenticate_user

  def params_without_action
    params.clone.delete_if { |k, v| %w(controller action).include? k }
  end

  protected

    def get_site
      if ENV['ONEBODY_SITE']
        Site.current = Site.where(name: ENV["ONEBODY_SITE"], active: true).first
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
        set_layout_variables
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

    # XXX
    def set_layout_variables
      @copyright_year  = Date.today.year
      @community_name  = CGI.escapeHTML(Setting.get(:name, :community))
    end

    # used by some anonymous controller actions to see if someone is logged in
    # (without redirecting if they are not)
    def get_user
      if id = session[:logged_in_id]
        Person.logged_in = @logged_in = Person.where(id: id).first
      end
    end

    def current_user
      @logged_in
    end

    def authenticate_user # default
      authenticate_user_with_http_basic_or_session
    end

    def authenticate_user_with_session
      if id = session[:logged_in_id]
        unless person = Person.where(id: id).first
          session[:logged_in_id] = nil
          redirect_to new_session_path
          return false
        end
        unless person.can_sign_in?
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
      unless params[:code] and Person.logged_in = @logged_in = Person.where(feed_code: params[:code], deleted: false).first
        authenticate_user_with_session
      end
    end

    def authenticate_user_with_http_basic_or_session
      Person.logged_in = @logged_in = nil
      authenticate_with_http_basic do |email, api_key|
        if email.to_s.any? and api_key.to_s.length == 50
          Person.logged_in = @logged_in = Person.where(email: email, api_key: api_key).first
          Person.logged_in = @logged_in = nil unless @logged_in and @logged_in.super_admin?
        end
      end
      unless @logged_in
        authenticate_user_with_session
      end
    end

    def check_full_access
      if @logged_in and !@logged_in.full_access?
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

    def me?
      @logged_in and @person and @logged_in == @person
    end

    def redirect_back(fallback=nil)
      if params[:from]
        redirect_to URI.parse(params[:from]).path
      elsif request.env["HTTP_REFERER"]
        redirect_to URI.parse(request.env["HTTP_REFERER"]).path
      elsif fallback
        redirect_to fallback
      else
        redirect_to people_path
      end
      return false # in case you want to halt action
    end

    def add_errors_to_flash(record)
      flash[:warning] = record.errors.full_messages.join('; ')
    end

    def only_admins
      unless @logged_in.admin?
        render text: t('only_admins'), layout: true, status: 401
        return false
      end
    end

    def feature_enabled?
      true
    end

    def can_export?
      @logged_in and @logged_in.admin?(:export_data) and Site.current.import_export_enabled?
    end

end

