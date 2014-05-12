module ApplicationHelper
  include TagsHelper
  include PicturesHelper
  include PhotosHelper
  include ERB::Util

  def banner_message
    if Setting.get(:features, :banner_message).to_s.any?
      h(Setting.get(:features, :banner_message))
    end
  end

  def mobile?
    session[:mobile] = params[:mobile] == 'true' if params[:mobile]
    session[:mobile] or (request.env["HTTP_USER_AGENT"].to_s =~ /mobile/i and session[:mobile].nil?)
  end

  STYLESHEET_MTIMES = {}

  def cached_mtime_for_path(path)
    if Rails.env.production?
      STYLESHEET_MTIMES[path] ||= File.mtime(Rails.root.join(path)).to_i.to_s
    else
      File.mtime(Rails.root.join(path)).to_i.to_s
    end
  end

  def stylesheet_path(browser=nil)
    theme_colors = Setting.get(:appearance, :theme_primary_color).to_s   + \
                   Setting.get(:appearance, :theme_secondary_color).to_s + \
                   Setting.get(:appearance, :theme_top_color).to_s       + \
                   Setting.get(:appearance, :theme_nav_color).to_s
    if browser == :ie
      path = 'public/stylesheets/style.ie.scss'
      browser_style_path(browser: :ie) + '?' + cached_mtime_for_path(path) + theme_colors
    elsif browser == :mobile
      path = 'public/stylesheets/style.mobile.scss'
      browser_style_path(browser: :mobile) + '?' + cached_mtime_for_path(path) + theme_colors
    else
      path = 'public/stylesheets/style.scss'
      style_path + '?' + cached_mtime_for_path(path) + theme_colors
    end
  end

  def heading
    if Site.current.logo.exists? and @hide_logo.nil?
      link_to(image_tag(Site.current.logo.url(:layout), alt: Setting.get(:name, :site)), '/')
    else
      Setting.get(:name, :site)
    end
  end

  def subheading
    if Setting.get(:name, :slogan).to_s.any? and !Site.current.logo.exists?
      Setting.get(:name, :slogan)
    end
  end

  def tab_link(title, url, active=false, id=nil)
    link_to(title, url, class: active ? 'active button' : 'button', id: id)
  end

  def menu_content
    render partial: 'people/menus'
  end

  def search_form
    form_tag(search_path, method: :get) do
      text_field_tag('name', nil, id: 'search_name', size: 20, placeholder: t('search.search_by_name'))
    end
  end

  def notice
    if flash[:warning] or flash[:notice]
      html = content_tag(:div, id: "notice", class: flash[:warning] ? 'warning' : nil) do
        flash[:warning] || flash[:notice]
      end
      unless flash[:sticky_notice]
        html << content_tag(:script, type: "text/javascript") do
          "$('#notice').fadeOut(15000);"
        end
      end
      html.html_safe
    end
  end

  def analytics_js
    if Rails.env.production?
      Setting.get(:services, :analytics)
    end
  end

  def preserve_breaks(text, make_safe=true)
    text = h(text.to_s) if make_safe
    text = text.gsub(/\n/, '<br/>').html_safe
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
    if page = Page.where(path: path, published: true).first
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
      area_code: format.index('(') ? true : false,
      groupings: groupings,
      delimiter: format.reverse.match(/[^d]/).to_s
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
    if form.respond_to?(:object)
      obj = form.object
    else
      obj = form
    end
    if obj.errors.any?
      (
        "<div class=\"errorExplanation\">" + \
        "<h3>#{t('There_were_errors')}</h3>" + \
        "<ul class=\"list\">" + \
        obj.errors.full_messages.map { |m| "<li>#{h m}</li>" }.join("\n") + \
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
        render partial: hook
      end.join("\n").html_safe
    end
  end

  def bar_chart_url(data, options={})
    options.symbolize_keys!
    options.reverse_merge!(set_count: 1, set_labels: nil, width: 400, height: 200, title: '', colors: ['4F9EC9', '79B933', 'FF9933'])
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
    options.reverse_merge!(width: 350, height: 200, title: '', colors: ['4F9EC9', '79B933', 'FF9933'])
    if data
      labels = data.keys
      counts = labels.inject([]) { |a, l| a << data[l]; a }
      labels.map! { |l| l.to_s.gsub('_', ' ') }
      "http://chart.apis.google.com/chart?chtt=#{options[:title]}&cht=p&chd=t:#{counts.join(',')}&chs=#{options[:width]}x#{options[:height]}&chl=#{labels.join('|')}&chco=#{options[:colors].join(',')}"
    else
      ''
    end
  end

  def sortable_column_heading(label, sort, keep_params=[])
    new_sort = (sort.split(',') + params[:sort].to_s.split(',')).uniq.join(',')
    options = {
      controller: params[:controller],
      action:     params[:action],
      id:         params[:id],
      sort:       new_sort
    }.merge(
      params.reject { |k, v| !keep_params.include?(k) }
    )
    url = url_for(options)
    link_to label, url
  end

  # prefer the object passed in, unless the object is nil or not yet persisted to disk
  # fallback is @logged_in.id (default) or @logged_in.family_id (pass :family_id as second param)
  def submenu_target(obj, fallback=:id)
    if obj and obj.persisted?
      obj
    else
      @logged_in.send(fallback)
    end
  end

  def params_without_action
    controller.params_without_action
  end

  def datepicker_format
    Setting.get(:formats, :date) =~ %r{%d/%m} ? 'dd/mm/yy' : 'mm/dd/yy'
  end

  # TODO remove after upgrade to Rails 4.1
  # https://github.com/rails/rails/blob/654dd04af6172/activesupport/lib/active_support/core_ext/string/output_safety.rb#L103
  JSON_ESCAPE = { '&' => '\u0026', '>' => '\u003e', '<' => '\u003c', "\u2028" => '\u2028', "\u2029" => '\u2029' }
  JSON_ESCAPE_REGEXP = /[\u2028\u2029&><]/u
  def json_escape(s)
    result = s.to_s.gsub(JSON_ESCAPE_REGEXP, JSON_ESCAPE)
    s.html_safe? ? result.html_safe : result
  end

  # TODO replace all inline JS links with unobtrusive JS
  def link_to_function(label, js, options={})
    options[:onclick] = js + ';return false;'
    link_to label, '#', options
  end

  class << self
    include ApplicationHelper
  end
end
