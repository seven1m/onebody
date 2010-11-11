# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  include PicturesHelper
  include PhotosHelper
  include ToursHelper

  def banner_message
    if Setting.get(:features, :banner_message).to_s.any?
      CGI.escapeHTML(Setting.get(:features, :banner_message))
    end
  end

  def head_tags
    (
      '<meta http-equiv="content-type" content="text/html; charset=utf-8" />' + \
      '<meta http-equiv="Pragma" content="no-cache"/>' + \
      '<meta http-equiv="no-cache"/>' + \
      '<meta http-equiv="Expires" content="-1"/>' + \
      '<meta http-equiv="Cache-Control" content="no-cache"/>'
    ).html_safe
  end

  def stylesheet_tags
    stylesheet_link_tag('jquery-ui-1.8.6.custom', 'style', :cache => true) + "\n" + \
    "<!--[if lte IE 8]>\n".html_safe + \
      stylesheet_link_tag('ie') + "\n" + \
    "<![endif]-->".html_safe
  end

  def javascript_tags
    javascript_include_tag('jquery-1.4.3.min', 'jquery-ui-1.8.6.custom.min', 'jquery.qtip-1.0.0-rc3.min.js', 'rails', 'application', :cache => true) + "\n" + \
    csrf_meta_tag + "\n" + \
    "<!--[if lte IE 8]>\n".html_safe + \
      javascript_include_tag('ie') + "\n" + \
    "<![endif]-->\n".html_safe + \
    "<script type=\"text/javascript\">logged_in = #{@logged_in ? @logged_in.id : 'null'}</script>".html_safe
  end

  def heading
    if (logo = Setting.get(:appearance, :logo)).to_s.any?
      img = image_tag("/assets/site#{Site.current.id}/#{logo}", :alt => Setting.get(:name, :site), :class => 'no-border', :style => 'float:left;margin-right:10px;')
      link_to(img, '/')
    else
      Setting.get(:name, :site)
    end
  end

  def subheading
    if Setting.get(:name, :slogan).to_s.any?
      Setting.get(:name, :slogan)
    end
  end

  def tab_link(title, url, active=false, id=nil)
    link_to(title, url, :class => active ? 'active button' : 'button', :id => id)
  end

  def nav_links
    html = ''
    html << "<li>#{tab_link t("nav.home"), stream_path, params[:controller] == 'streams', 'home-tab'}</li>"
    if @logged_in
      profile_link = person_path(@logged_in, :tour => params[:tour])
    else
      profile_link = people_path
    end
    html << "<li><div>#{tab_link t("nav.profile"), profile_link, params[:controller] == 'people' && me?, 'profile-tab'}</div></li>"
    if Setting.get(:features, :groups) and (Site.current.max_groups.nil? or Site.current.max_groups > 0)
      html << "<li>#{ tab_link t("nav.groups"), groups_path, params[:controller] == 'groups', 'group-tab'}</li>"
    end
    html << "<li>#{tab_link t("nav.directory"), new_search_path, %w(searches printable_directories).include?(params[:controller]), 'directory-tab'}</li>"
    html
  end

  def common_nav_links
    html = ''
    html << "<li class=\"platform\"><a href=\"http://beonebody.com\">OneBody v2</a></li>"
    if @logged_in
      html << "<li>#{link_to t("session.sign_out"), session_path, :method => :delete}</li>"
    end
    if Setting.get(:services, :sermondrop_url).to_s.any?
      html << "<li>#{link_to t("nav.podcasts"), podcasts_path}</li>"
    end
    html << "<li><a href=\"/admin\">admin</a></li>"
    html
  end

  def menu_content
    render :partial => 'people/menus'
  end

  def search_form
    "<form><input name=\"name\" id=\"search_name\" size=\"20\" placeholder=\"#{t('search.search_by_name')}\"/></form>".html_safe
  end

  def notice
    if flash[:warning] or flash[:notice]
      <<-HTML
        <div id="notice" #{flash[:warning] ? 'class="warning"' : nil}>#{flash[:warning] || flash[:notice]}</div>
        <script type="text/javascript">
          #{!flash[:sticky_notice] && "setTimeout(\"$('#notice').hide('slow');\", 15000)"}
        </script>
      HTML
    end
  end

  def footer_content
    "&copy; #{Date.today.year}, #{Setting.get(:name, :community)} &middot; " + \
    "<a href=\"/pages/help/privacy_policy\">#{t('layouts.privacy_policy')}</a> &middot; " + \
    t('layouts.powered_by_html')
  end

  def personal_nav_links
    html = ''
    if @logged_in
      html << "<li class=\"personal\">"
      html << link_to(image_tag('door_in.png', :alt => t('session.sign_out'), :class => 'icon') + ' ' + t('session.sign_out'), session_path, :method => 'delete')
      html << "</li>"
      html << "<li class=\"personal\">"
      if session[:touring]
        html << link_to(image_tag('car.png', :alt => t('session.tour'), :class => 'icon') + ' ' + t('session.tour'), tour_path(:stop => true), :class => 'active')
      else
        html << link_to(image_tag('car.png', :alt => t('session.tour'), :class => 'icon') + ' ' + t('session.tour'), tour_path(:start => true), :id => 'tour_link')
      end
      html << "</li>"
      if @logged_in.admin?
        html << "<li class=\"personal\">"
        html << link_to(image_tag('cog.png', :alt => t('admin.admin'), :class => 'icon') + ' ' + t('admin.admin'), admin_path, :class => params[:controller] =~ /^admin/ ? 'active' : nil)
        html << "</li>"
      end
    else
      html << "<li class=\"personal\">"
      html << link_to(image_tag('door.png', :alt => t('session.sign_in'), :class => 'icon') + ' ' + t('session.sign_in'), new_session_path)
      html << "</li>"
    end
    html
  end

  def news_js
    nil # not used any more
  end

  def analytics_js
    if Rails.env.production?
      Setting.get(:services, :analytics)
    end
  end

  def preserve_breaks(text, make_safe=true)
    text = h(text.to_s) if make_safe
    text.gsub(/\n/, '<br/>')
  end

  def remove_excess_breaks(text)
    text.gsub(/(\n\s*){3,}/, "\n\n")
  end

  def image_tag(location, options)
    options[:title] = options[:alt] if options[:alt]
    super(location, options)
  end

  def simple_url(url)
    url.sub(/^https?:\/\//, '').sub(/\/$/, '')
  end

  def me?
    @logged_in and @person and @logged_in == @person
  end

  def help_path(name=nil)
    page_for_public_path("help/#{name}")
  end

  def system_path(name=nil)
    page_for_public_path("system/#{name}")
  end

  def render_page_content(path)
    if page = Page.find_by_path_and_published(path, true)
      sanitize_html(page.body)
    end
  end

  def format_phone(phone, mobile=false)
    format = Setting.get(:formats, mobile ? :mobile_phone : :phone)
    return phone if format.blank?
    groupings = format.scan(/d+/).map { |g| g.length }
    groupings = [3, 3, 4] unless groupings.length == 3
    ActionController::Base.helpers.number_to_phone(
      phone,
      :area_code => format.index('(') ? true : false,
      :groupings => groupings,
      :delimiter => format.reverse.match(/[^d]/).to_s
    )
  end

  def custom_field_name(index)
    n = Setting.get(:features, :custom_person_fields)[index]
    n ? n.sub(/\*/, '') : nil
  end

  def sanitize_html(html)
    return nil unless html
    Sanitize.clean(html, Sanitize::Config::ONEBODY).html_safe
  end

  def error_messages_for(form)
    if form.object.errors.any?
      (
        "<div class=\"errorExplanation\">" + \
        "<h3>#{t('There_were_errors')}</h3>" + \
        "<ul class=\"list\">" + \
        form.object.errors.full_messages.map { |m| "<li>#{h m}</li>" }.join("\n") + \
        "</ul>" + \
        "</div>"
      ).html_safe
    end
  end

  def domain_name_from_url(url)
    url =~ /^https?:\/\/([^\/]+)/
    $1
  end

  def render_plugin_hook(name)
    if hooks = PLUGIN_HOOKS[name]
      hooks.map do |hook|
        render :partial => hook
      end.join("\n")
    end
  end

  def bar_chart_url(data, options={})
    options.symbolize_keys!
    options.reverse_merge!(:set_count => 1, :set_labels => nil, :width => 400, :height => 200, :title => '', :colors => ['4F9EC9', '79B933', 'FF9933'])
    labels = data.map { |p| p[0] }
    counts = []
    (0...options[:set_count]).each do |set|
      counts[set] = data.map { |p| p[set+1] }
    end
    max = data.map { |p| p[1..-1].sum }.max
    "http://chart.apis.google.com/chart?chtt=#{options[:title]}&cht=bvs&chxt=x,y&chxr=1,0,#{max}#{options[:interval] && ','+options[:interval].to_s}&chds=0,#{max}&chd=t:#{counts.map { |c| c.join(',') }.join('|')}&chs=#{options[:width]}x#{options[:height]}&chl=#{labels.join('|')}&chbh=a&chco=#{options[:colors].join(',')}" + (options[:set_labels] ? "&chdl=#{options[:set_labels].join('|')}" : '')
  end

  def pie_chart_url(data, options={})
    options.symbolize_keys!
    options.reverse_merge!(:width => 350, :height => 200, :title => '', :colors => ['4F9EC9', '79B933', 'FF9933'])
    labels = data.keys
    counts = labels.inject([]) { |a, l| a << data[l]; a }
    labels.map! { |l| l.to_s.gsub('_', ' ') }
    "http://chart.apis.google.com/chart?chtt=#{options[:title]}&cht=p&chd=t:#{counts.join(',')}&chs=#{options[:width]}x#{options[:height]}&chl=#{labels.join('|')}&chco=#{options[:colors].join(',')}"
  end

  def sortable_column_heading(label, sort, keep_params=[])
    new_sort = (sort.split(',') + params[:sort].to_s.split(',')).uniq.join(',')
    options = {
      :controller => params[:controller],
      :action     => params[:action],
      :id         => params[:id],
      :sort       => new_sort
    }.merge(
      params.reject { |k, v| !keep_params.include?(k) }
    )
    url = url_for(options)
    link_to label, url
  end

  def iphone_back_button(url=nil, label='Back')
    if url
      "<a class=\"button backButton\" rel=\"external\" href=\"#{url}\">#{label}</a>"
    elsif params[:iphoneAjax]
      "<a class=\"back\" href=\"#home\">#{label}</a>"
    else
      "<a class=\"button backButton\" rel=\"external\" href=\"/stream\">#{label}</a>"
    end
  end

  def iphone?
    controller.iphone?
  end

  def params_without_action
    controller.params_without_action
  end

  class << self
    include ApplicationHelper
  end
end

module ActionView
  module Helpers
    module FormHelper
      def phone_field(object_name, method, options = {})
        options[:value] = format_phone(options[:object][method], mobile=(method.to_s =~ /mobile/))
        options[:size] ||= 15
        InstanceTag.new(object_name, method, self, options.delete(:object)).to_input_field_tag("text", options)
      end
    end
    class FormBuilder
      def phone_field(method, options = {})
        @template.phone_field(@object_name, method, options.merge(:object => @object))
      end
      def date_field(method, options = {})
        options[:value] = self.object[method].to_s(:date) rescue ''
        options[:size] ||= 12
        text_field(method, options)
      end
    end
    module FormTagHelper
      def date_field_tag(name, value = nil, options = {})
        value = value.to_s(:date) rescue ''
        options[:size] ||= 12
        text_field_tag(name, value, options)
      end
    end
  end
end
