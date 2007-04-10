# Rails plugin that makes clever use of Ruby's built-in String taint checks
# to sanitize text attributes coming from ActiveRecord

# This is still a work in progress and will no doubt bite you in one place
# or another. But, it forces the developer to go out of their way to insert
# raw, unescaped text data into web pages.

require 'active_record'

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
                if value = read_attribute('#{attr}')
                  value = value.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
                  value.untaint
                end
                return value
              end
              def #{attr}_without_escaping
                read_attribute('#{attr}')
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

module ActiveRecord
  class Base
    alias_method :non_tainting_read_attribute, :read_attribute
    def read_attribute(name)
      v = non_tainting_read_attribute(name)
      v.taint if v.is_a? String
      return v
    end
  end
end

module ApplicationHelper
  def html_escape(s)
    if s.tainted?
      s = s.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
      s.untaint
    end
    return s
  end
  alias_method :h, :html_escape
end