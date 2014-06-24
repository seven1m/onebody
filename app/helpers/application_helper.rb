module ApplicationHelper

  # TODO do we need these includes any more?
  include TagsHelper
  include PicturesHelper
  include PhotosHelper

  # TODO needed?
  include ERB::Util

  def flash_class(level)
    case level
      when :info    then 'flash callout callout-info'
      when :notice  then 'flash callout callout-info'
      when :success then 'flash callout callout-success'
      when :error   then 'flash callout callout-danger'
      when :warning then 'flash callout callout-warning'
    end
  end

  def flash_messages
    flash.map do |key, value|
      content_tag(:div, preserve_breaks(value), class: flash_class(key))
    end.join.html_safe
  end

  def preserve_breaks(text, make_safe=true)
    text = h(text.to_s) if make_safe
    text = text.gsub(/\n/, '<br/>').html_safe
  end

  def remove_excess_breaks(text)
    text.gsub(/(\n\s*){3,}/, "\n\n")
  end

  def format_text(text)
    text = auto_link(text)
    text = remove_excess_breaks(text).html_safe
    preserve_breaks(text, false)
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

  def link_to_phone(phone, options={})
    label = options.delete(:label)
    label ||= format_phone(phone, options.delete(:mobile))
    link_to label, "tel:#{phone.digits_only}", options
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
      content_tag(:div, class: 'callout callout-danger form-errors') do
        content_tag(:h4, t('There_were_errors')) +
        content_tag(:ul, class: 'list') do
          uniq_errors(obj).map do |attribute, message|
            content_tag(:li, message, data: { attribute: "#{obj.class.name.underscore}_#{attribute}" })
          end.join.html_safe
        end
      end
    end
  end

  def uniq_errors(object)
    # note: uniq doesn't work here since it isn't really an array
    seen = []
    object.errors.select do |attr, message|
      unless seen.include?(message)
        seen << message
        message
      end
    end
  end

  # TODO
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

  def params_without_action
    controller.params_without_action
  end

  def datepicker_format
    Setting.get(:formats, :date) =~ %r{%d/%m} ? 'dd/mm/yyyy' : 'mm/dd/yyyy'
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

  def icon(css_class, options = {})
    options[:class] = css_class
    content_tag(:i, '', options)
  end

  def setting(section, name)
    if name.is_a?(Array)
      name.detect { |n| Setting.get(section, n) }
    else
      Setting.get(section, name)
    end
  end

  def pagination(scope, options={})
    options.reverse_merge!(renderer: BootstrapPagination::Rails)
    will_paginate scope, options
  end

  def truncate_words(text, options={})
    truncate(text, options.reverse_merge(separator: ' ', omission: '…'))
  end

  def map_header(object)
    if object.mapable?
      content_for(:header) do
        raw(
          content_tag(:div, '', id: 'map', data: { latitude: object.latitude, longitude: object.longitude, address: preserve_breaks(object.location), notice: t('maps.notice') }) +
          content_tag(:section, class: 'content-header map-overlay') do
            breadcrumbs +
            content_tag(:h1) do
              sub = (s = content_for(:sub_title)) ? content_tag(:small, s) : ''
              (@title + sub).html_safe
            end
          end
        )
      end
    end
  end

  # TODO reevaluate with Rails 4.1
  # this is an ugly hack for Rails 4 because I18n.exception_handler isn't working with the t() helper
  def t(*args)
    if Rails.env.production?
      super
    else
      super.tap do |result|
        if result =~ /"(translation missing: .*)"/
          raise $1
        end
      end
    end
  end

  class << self
    include ApplicationHelper
  end
end
