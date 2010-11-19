require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module OneBody
  class Application < Rails::Application
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths << "#{config.root}/app/sweepers"

    # Custom directory for plugins
    # FIXME
    #config.plugin_paths << "#{config.root}/plugins"

    # Cache store location
    config.action_controller.cache_store = [:file_store, "#{config.root}/cache"]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.default_locale = File.exist?("#{config.root}/config/locale") ? File.read("#{config.root}/config/locale").strip.to_sym : :en
    config.i18n.load_path += Dir["#{config.root}/plugins/**/config/locales/*.{rb,yml}"]

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
  end
end
