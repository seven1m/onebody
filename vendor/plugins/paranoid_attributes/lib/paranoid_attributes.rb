require 'active_record'

class String
  attr_accessor :escaped
end

module Foo
  module Acts #:nodoc:
    module ParnoidAttributesPlugin #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def paranoid_attributes(*attrs)
          attrs.each do |attr|
            class_eval <<-END
              def #{attr}
                value = read_attribute('#{attr}').to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
                value.escaped = true
                return value
              end
              def #{attr}_without_escaping
                value = read_attribute('#{attr}').to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
                value.escaped = true
                return value
              end
            END
          end
        end
      end

    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include Foo::Acts::ParnoidAttributesPlugin
end

module ApplicationHelper
  def html_escape(s)
    unless s.escaped
      s = s.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
      s.escaped = true
    end
    return s
  end
  alias_method :h, :html_escape
end