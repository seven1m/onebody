module Rails
  class Plugin
    class GemLocator < Locator
      def plugins
        specs  = initializer.configuration.gems.map(&:specification)
        specs += Gem.loaded_specs.values.select do |spec|
          spec.loaded_from && # prune stubs
            File.exist?(File.join(spec.full_gem_path, "rails", "init.rb"))
        end
        specs.compact!

        require "rubygems/dependency_list"

        deps = Gem::DependencyList.new
        specs.each do |spec|
          deps.add(spec)
        end

        deps.dependency_order.collect do |spec|
          Rails::GemPlugin.new(spec)
        end
      end
    end
  end
end
