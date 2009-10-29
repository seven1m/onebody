module ActionController
  module Routing
    class RouteSet
      def draw_with_disablement(&block)
        draw_without_disablement(&block) unless defined?(DISABLE_ROUTES)
      end
      alias_method_chain :draw, :disablement
    end
  end
end
