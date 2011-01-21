module ActiveRecord
  class Base
    class << self
      def default_scope(options = {})
        reset_scoped_methods

        default_scoping = self.default_scoping.dup
        previous = default_scoping.pop

        if previous.respond_to?(:call) or options.respond_to?(:call)
          new_default_scope = lambda do
            sane_options = options.respond_to?(:call) ? options.call : options
            sane_previous = previous.respond_to?(:call) ? previous.call : previous
            construct_finder_arel sane_options, sane_previous
          end
        else
          new_default_scope = construct_finder_arel options, previous
        end

        self.default_scoping = default_scoping << new_default_scope
      end

      protected
        def current_scoped_methods
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
