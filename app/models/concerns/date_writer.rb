require 'active_support/concern'

module Concerns
  module DateWriter
    extend ActiveSupport::Concern

    module ClassMethods
      def date_writer(*attrs)
        attrs.each do |attr|
          define_method "#{attr}=".to_sym do |string|
            self[attr] = date_from_string(string)
          end
        end
      end
    end

    def date_from_string(string)
      if string.is_a?(String) && !string.empty? && (date = Date.parse_in_locale(string).try(:rfc3339))
        date
      else
        string
      end
    end
  end
end
