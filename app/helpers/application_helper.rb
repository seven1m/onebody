# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  include PicturesHelper
  include PhotosHelper

  def preserve_breaks(text, make_safe=true)
    text = h(text.to_s) if make_safe
    simple_format(text.to_s)
  end
  
  def remove_excess_breaks(text)
    text.gsub(/(\n\s*){3,}/, "\n\n")
  end
  
  def hide_contact_details(text)
    text.gsub(/\(?\d\d\d\)?[\s\-\.]?\d\d\d[\s\-\.]\d\d\d\d/, '[phone number protected]').gsub(/[a-z\-_\.0-9]+@[a-z\-0-9\.]+\.[a-z]{2,4}/, '[email address protected]')
  end
  
  def image_tag(location, options)
    options[:title] = options[:alt] if options[:alt]
    super(location, options)
  end
  
  def simple_url(url)
    url.gsub(/^https?:\/\//, '').gsub(/\/$/, '')
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
    Page.find_by_path(path).body rescue ''
  end
  
  def format_phone(phone, mobile=false)
    format = Setting.get(:formats, mobile ? :mobile_phone : :phone)
    groupings = format.scan(/d+/).map { |g| g.length }
    groupings = [3, 3, 4] unless groupings.length == 3
    ActionController::Base.helpers.number_to_phone(
      phone,
      :area_code => format.index('(') ? true : false,
      :groupings => groupings,
      :delimiter => format.reverse.match(/[^d]/).to_s
    )
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
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_input_field_tag("text", options)
      end
      def date_field(object_name, method, options = {})
        options[:value] = options[:object][method].to_s(:date) rescue ''
        options[:size] ||= 12
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_input_field_tag("text", options)
      end  
    end
    class FormBuilder
      def phone_field(method, options = {})
        @template.phone_field(@object_name, method, options.merge(:object => @object))
      end
      def date_field(method, options = {})
        @template.date_field(@object_name, method, options.merge(:object => @object))
      end
    end
  end
end
