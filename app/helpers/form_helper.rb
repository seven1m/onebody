module FormHelper
end

module ActionView
  module Helpers
    module FormHelper
      def phone_field(object_name, method, options = {})
        mobile = method.to_s =~ /mobile/
        options[:value] = format_phone(options[:object][method], mobile)
        options[:size] ||= 15
        Tags::TextField.new(object_name, method, self, options).render
      end
    end

    class FormBuilder
      def phone_field(method, options = {})
        @template.phone_field(@object_name, method, options.merge(object: @object))
      end
    end

    module FormTagHelper
      # nothing yet
    end
  end
end
