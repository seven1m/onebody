class ApplicationController < ActionController::Base
  #protect_from_forgery

  cache_sweeper :stream_item_sweeper, :only => %w(create update destroy)

  layout 'default.html'

  before_filter :get_site
  before_filter :feature_enabled?
  before_filter :authenticate_user
  before_filter :detect_mobile

  def iphone?
    session[:iphone] or (request.env["HTTP_USER_AGENT"] and request.env["HTTP_USER_AGENT"] =~ /Mobile\/.+Safari/ and session[:iphone].nil?)
  end

  def params_without_action
    params.clone.delete_if { |k, v| %w(controller action).include? k }
  end

  private
    def get_site
      if ENV['ONEBODY_SITE']
        Site.current = Site.find_by_name_and_active(ENV['ONEBODY_SITE'], true)
      elsif Setting.get(:features, :multisite)
        Site.current = Site.find_by_host_and_active(request.host, true)
      else
        Site.current = Site.find(1) or raise I18n.t('application.no_default_site')
      end
      if Site.current
        if Site.current.settings_changed_at and SETTINGS['timestamp'] < Site.current.settings_changed_at
          RAILS_DEFAULT_LOGGER.info('Reloading Settings Cache...')
          Setting.precache_settings(true)
        end
        update_view_paths
        set_locale
        set_time_zone
        set_local_formats
        set_layout_variables
      elsif site = Site.find_by_secondary_host_and_active(request.host, true)
        redirect_to 'http://' + site.host
        return false
      elsif request.host =~ /^www\./
        redirect_to request.url.sub(/^(https?:\/\/)www\./, '\1')
        return false
      else
        render :text => I18n.t('application.no_site_configured', :host => request.host), :status => 404
        return false
      end
    end

    def update_view_paths
      theme_name = get_theme_name
      if theme_name == 'custom'
        theme_name = "custom/site#{Site.current.id}"
      end
      theme_dirs = [Rails.root.join('themes', theme_name)]
      if defined?(DEPLOY_THEME_DIR)
        theme_dirs = [File.join(DEPLOY_THEME_DIR, theme_name)] + theme_dirs
      end
      prepend_view_path(theme_dirs)
      @view_paths = lookup_context.view_paths
    end

    def set_locale
      I18n.locale = Setting.get(:system, :language)
    end

    def set_time_zone
      Time.zone = Setting.get(:system, :time_zone)
    end

    def set_local_formats
      Time::DATE_FORMATS.merge!(
        :default           => Setting.get(:formats, :full_date_and_time),
        :date              => Setting.get(:formats, :date),
        :time              => Setting.get(:formats, :time),
        :date_without_year => Setting.get(:formats, :date_without_year)
      )
    end

    def set_layout_variables
      @site_name       = CGI.escapeHTML(Setting.get(:name, :site))
      @show_subheading = Setting.get(:appearance, :show_subheading)
      @copyright_year  = Date.today.year
      @community_name  = CGI.escapeHTML(Setting.get(:name, :community))
    end

    def get_theme_name
      if params[:theme] and params[:theme] =~ /^[a-z0-9_]+$/
        params[:theme]
      else
        Setting.get(:appearance, :theme)
      end
    end

    # used by some anonymous controller actions to see if someone is logged in
    # (without redirecting if they are not)
    def get_user
      if id = session[:logged_in_id]
        Person.logged_in = @logged_in = Person.find_by_id(id)
      end
    end

    def authenticate_user # default
      authenticate_user_with_http_basic_or_session
    end

    def authenticate_user_with_session
      if id = session[:logged_in_id]
        unless person = Person.find_by_id(id)
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
        if Site.current.id != @logged_in.site_id
          session[:logged_in_id] = nil
          redirect_to new_session_path
          return false
        end
      else
        redirect_to new_session_path(:from => request.request_uri)
        return false
      end
    end

    def authenticate_user_with_code_or_session
      Person.logged_in = @logged_in = nil
      unless params[:code] and Person.logged_in = @logged_in = Person.find_by_feed_code_and_deleted(params[:code], false)
        authenticate_user_with_session
      end
    end

    def authenticate_user_with_http_basic_or_session
      Person.logged_in = @logged_in = nil
      authenticate_with_http_basic do |email, api_key|
        if email.to_s.any? and api_key.to_s.length == 50
          Person.logged_in = @logged_in = Person.find_by_email_and_api_key(email, api_key)
          Person.logged_in = @logged_in = nil unless @logged_in and @logged_in.super_admin?
        end
      end
      unless @logged_in
        authenticate_user_with_session
      end
    end

    def generate_encryption_key
      key = OpenSSL::PKey::RSA.new(1024)
      @public_modulus  = key.public_key.n.to_s(16)
      @public_exponent = key.public_key.e.to_s(16)
      session[:key] = key.to_pem
    end

    def decrypt_password(pass)
      if session[:key]
        key = OpenSSL::PKey::RSA.new(session[:key])
        begin
          key.private_decrypt(Base64.decode64(pass))
        rescue OpenSSL::PKey::RSAError
          false
        end
      else
        false
      end
    end

    def detect_mobile
      session[:iphone] = params[:iphone] == 'true' if params[:iphone]
      if iphone?
        request.format = :iphone
        if params[:iphoneAjax]
          self.class.layout 'iphone_bare.html'
        else
          self.class.layout 'iphone.html'
        end
      else
        self.class.layout 'default.html'
      end
    end

    def rescue_action_with_page_detection(exception)
      get_site
      path, args = request.request_uri.downcase.split('?')
      if exception.is_a?(ActionController::RoutingError) and @page = Page.find_by_path(path)
        redirect_to '/pages/' + @page.path + (args ? "?#{args}" : '')
      else
        rescue_action_without_page_detection(exception)
      end
    end
    alias_method_chain :rescue_action, :page_detection

    def me?
      @logged_in and @person and @logged_in == @person
    end

    def redirect_back(fallback=nil)
      if params[:from]
        redirect_to(params[:from])
      elsif request.env["HTTP_REFERER"]
        redirect_to(request.env["HTTP_REFERER"])
      elsif fallback
        redirect_to(fallback)
      else
        redirect_to(people_path)
      end
      return false # in case you want to halt action
    end

    def add_errors_to_flash(record)
      flash[:warning] = record.errors.full_messages.join('; ')
    end

    def only_admins
      unless @logged_in.admin?
        render :text => I18n.t('only_admins'), :layout => true, :status => 401
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

