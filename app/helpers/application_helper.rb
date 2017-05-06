# encoding: utf-8

module ApplicationHelper
  include TagsHelper # provided by acts_as_taggable_on_steroids

  FLASH_CLASSES = {
    info:    'flash callout callout-info',
    notice:  'flash callout callout-info',
    success: 'flash callout callout-success',
    error:   'flash callout callout-danger',
    warning: 'flash callout callout-warning'
  }.with_indifferent_access

  def flash_messages
    flash.map do |key, value|
      if (css_class = FLASH_CLASSES[key])
        content_tag(:div, preserve_breaks(value), class: css_class)
      else
        ''
      end
    end.join.html_safe
  end

  def preserve_breaks(text, make_safe = true)
    text = h(text.to_s) if make_safe
    text.gsub(/\n/, '<br/>').html_safe
  end

  def remove_excess_breaks(text)
    text.gsub(/(\n\s*){3,}/, "\n\n")
  end

  def format_text(text)
    text = auto_link(text)
    text = remove_excess_breaks(text).html_safe
    preserve_breaks(text, false)
  end

  def simple_url(url, options = { www: true })
    if options[:www]
      regex = %r{\Ahttps?://}
    else
      regex = %r{\Ahttps?://(www\.)?}
    end
    url.sub(regex, '').sub(/\/$/, '')
  end

  def safe_url(url)
    return unless url =~ %r{\Ahttps?\://.+}
    "#{url}" # wrap in new string so Hakiri is happy
  end

  def me?
    @logged_in && @person && @logged_in == @person
  end

  def format_phone(phone, mobile = false)
    return '' if phone.blank?
    format = Setting.get(:formats, mobile ? :mobile_phone : :phone)
    return phone if format.blank?
    groupings = format.scan(/d+/).map(&:length)
    groupings = [3, 3, 4] unless groupings.length == 3
    ActionController::Base.helpers.number_to_phone(
      phone,
      area_code: format.index('(') ? true : false,
      groupings: groupings,
      delimiter: format.reverse.match(/[^d]/).to_s
    )
  end
  module_function :format_phone

  def link_to_phone(phone, options = {})
    return if phone.blank?
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
    error_messages_for_object(obj)
  end

  def error_messages_for_object(obj)
    return if obj.errors.empty?
    content_tag(:div, class: 'callout callout-danger form-errors') do
      content_tag(:h4, t('There_were_errors')) +
      content_tag(:ul, class: 'list') do
        uniq_errors(obj).map do |attribute, message|
          content_tag(:li, message, data: { attribute: "#{obj.class.name.underscore}_#{attribute}" })
        end.join.html_safe
      end
    end
  end

  def uniq_errors(object)
    # note: uniq doesn't work here since it isn't really an array
    seen = []
    object.errors.select do |_attr, message|
      unless seen.include?(message)
        seen << message
        message
      end
    end
  end

  def sortable_column_heading(label, sort, keep_params = [])
    options = {
      controller: params[:controller],
      action:     params[:action],
      id:         params[:id],
      sort:       sort_params(sort)
    }.merge(
      keep_params == :all ? params.except(:controller, :action, :sort) : params.reject { |k| !keep_params.include?(k) }
    )
    url = url_for(options)
    link_to label, url
  end

  def sort_params(sort)
    old_params = params[:sort].to_s.split(',')
    (sort.split(',') + old_params).uniq.join(',')
  end

  def alternate_sort_param(*alternates)
    current = params[:sort].to_s.split(',').first
    return alternates.first unless current.present?
    current_index = alternates.index(current)
    return alternates.first unless current_index
    next_index = current_index + 1
    return alternates.first if next_index >= alternates.size
    alternates[next_index]
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

  # TODO: replace all inline JS links with unobtrusive JS
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

  def pagination(scope, options = {})
    options.reverse_merge!(renderer: BootstrapPagination::Rails)
    will_paginate scope, options
  end

  def truncate_words(text, options = {})
    truncate(text, options.reverse_merge(separator: ' ', omission: '…'))
  end

  def truncate_html(html, length:)
    HTML_Truncator.truncate(html, length)
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

  def time_to_s(time, format, if_nil = '')
    if time
      time.to_s(format)
    else
      if_nil
    end
  end

  def options_from_i18n(key)
    I18n.t(key).invert
  rescue I18n::MissingTranslationData
    I18n.locale = 'en'
    result = I18n.t(key).invert
    OneBody.set_locale
    result
  end

  def connection_secured?
    (request.headers['HTTP_X_FORWARDED_PROTO'] || request.scheme) == 'https'
  end

  def connection_is_proxied_but_protocol_unknown?
    request.headers['HTTP_X_FORWARDED_FOR'] && request.headers['HTTP_X_FORWARDED_PROTO'].nil?
  end

  def tls_warning(email_setup: false)
    return if connection_secured?
    render partial: 'layouts/tls_warning', locals: {
      email_setup: email_setup,
      proxy_missing_protocol_header: connection_is_proxied_but_protocol_unknown?
    }
  end
end
