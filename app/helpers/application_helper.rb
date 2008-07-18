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
  
  def select_a_date(name, id, value)
    months = MONTHS.map { |label, num| %(<option value="#{num}" #{value and value.month == num ? 'selected="selected"' : ''}>#{label}</option>) }
    days = (1..31).map { |num| %(<option value="#{num}" #{value and value.day == num ? 'selected="selected"' : ''}>#{num}</option>) }
    years = YEARS.to_a.reverse.map { |num| %(<option value="#{num}" #{value and value.year == num ? 'selected="selected"' : ''}>#{num}</option>) }
    %(<select name="#{name}[month]" id="#{id}_month"><option value="" #{value ? '' : 'selected="selected"'}></option>#{months}</select>
    <select name="#{name}[day]" id="#{id}_day"><option value="" #{value ? '' : 'selected="selected"'}></option>#{days}</select>
    <select name="#{name}[year]" id="#{id}_year"><option value="" #{value ? '' : 'selected="selected"'}></option>#{years}</select>)
  end
  
  def simple_url(url)
    url.gsub(/^https?:\/\//, '').gsub(/\/$/, '')
  end
  
  def me?
    @logged_in and @person and @logged_in == @person
  end
end

module ActionView
  module Helpers
    module FormHelper
      def phone_field(object_name, method, options = {})
        options[:area_code] = true if options[:area_code].nil?
        options[:value] = number_to_phone(options[:object][method], :area_code => options.delete(:area_code))
        options[:size] ||= 15
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_input_field_tag("text", options)
      end
      def date_field(object_name, method, options = {})
        options[:value] = options[:object][method].to_s(:date) rescue nil
        options[:size] ||= 12
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_input_field_tag("text", options)
      end  
      # @person.birthday.to_s(:date)
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
