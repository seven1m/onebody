module FormHelper
end

module ActionView
  module Helpers
    module FormHelper
      include ApplicationHelper

      def phone_field(object_name, method, options = {})
        mobile = method.to_s =~ /mobile/
        options[:value] = format_phone(options[:object].send(method), mobile)
        options[:size] ||= 15
        Tags::TextField.new(object_name, method, self, options).render
      end

      def date_field(object_name, method, options = {})
        val = options[:object].send(method)
        options[:value] = val && val.respond_to?(:strftime) ? val.to_s(:date) : nil
        options[:placeholder] = date_format
        options[:class] = "#{options[:class]} date-field".strip
        Tags::TextField.new(object_name, method, self, options).render
      end

      def date_field_tag(name, value = nil, options = {})
        value = value.to_s(:date) if value.respond_to?(:strftime)
        options[:placeholder] = date_format
        options[:class] = "#{options[:class]} date-field".strip
        text_field_tag(name, value, options)
      end
    end

    class FormBuilder
      def phone_field(method, options = {})
        @template.phone_field(@object_name, method, options.merge(object: @object))
      end

      def date_field(method, options = {})
        @template.date_field(@object_name, method, options.merge(object: @object))
      end
    end

    module FormTagHelper
      # nothing yet
    end
  end
end
