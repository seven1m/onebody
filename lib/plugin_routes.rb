module ActionController
  module Routing
    class RouteSet
      def draw_plugin_routes
        Dir[Rails.root + 'plugins/*/routes.rb'].each do |routes_file|
          plugin = routes_file.match(/plugins\/(.+?)\/routes\.rb$/)[1]
          if File.exist?(Rails.root + 'plugins/' + plugin + '/enable')
            load(routes_file)
            Kernel.const_get(plugin.classify + 'Plugin')::Routes.new.send('draw', Mapper.new(self))
          end
        end
      end
    end
  end
end
