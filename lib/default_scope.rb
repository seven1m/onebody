module ActiveRecord
  class Base
    class << self
      protected
        def current_scoped_methods #:nodoc:
          method = scoped_methods.last
          if method.respond_to?(:call)
            unscoped(&method)
          else
            method
          end
        end
    end
  end
end
