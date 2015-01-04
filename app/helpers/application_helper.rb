# encoding: utf-8

module ApplicationHelper

  # TODO do we need these includes any more?
  include TagsHelper
  include PicturesHelper
  include PhotosHelper

  # TODO needed?
  include ERB::Util

  FLASH_CLASSES = {
    info:    'flash callout callout-info',
    notice:  'flash callout callout-info',
    success: 'flash callout callout-success',
    error:   'flash callout callout-danger',
    warning: 'flash callout callout-warning'
  }.with_indifferent_access

  def flash_messages
    flash.map do |key, value|
      if css_class = FLASH_CLASSES[key]
        content_tag(:div, preserve_breaks(value), class: css_class)
      else
        ''
      end
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

  def simple_url(url, options={ www: true })
    if options[:www]
      regex = /^https?:\/\//
    else
      regex = /^https?:\/\/(www\.)?/
    end
    url.sub(regex, '').sub(/\/$/, '')
  end

  def safe_url(url)
    if url =~ /\Ahttps?\:\/\/.+/
      "#{url}" # wrap in new string so Hakiri is happy
    end
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

  def date_format
    placeholder = Setting.get(:formats, :date)
      .gsub(/%Y/, I18n.t('date_format.YYYY'))
      .gsub(/%m/, I18n.t('date_format.MM'))
      .gsub(/%d/, I18n.t('date_format.DD'))
    placeholder unless placeholder.include?('%')
  end

  def datepicker_format
    date_format.downcase
  end

  # TODO replace all inline JS links with unobtrusive JS
  def link_to_function(*args, &block)
    options = args.extract_options!
    js = args.pop
    options[:onclick] = js + ';return false;'
    args += [js, options]
    link_to(*args, &block)
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
      data = { latitude: object.latitude,
               longitude: object.longitude,
               address: preserve_breaks(object.pretty_address),
               notice: t('maps.notice'),
               protocol: Setting.get(:features, :ssl) ? 'https' : 'http' }
      content_for(:header) do
        raw(
          content_tag(:div, '', id: 'map', data: data) +
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

  def analytics_js
    if params[:controller] == 'administration/settings'
      # workaround for Safari bug (see https://github.com/churchio/onebody/issues/262)
      return
    end
    setting(:services, :analytics).to_s.html_safe if Rails.env.production?
  end

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
