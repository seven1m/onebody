require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dir[File.dirname(__FILE__) + '/../plugins/**/lib/*'].each do |plugin|
  require plugin.sub(/\.rb$/, '')
end

require_relative '../lib/console'
require_relative '../lib/version_info'

module OneBody
  extend VersionInfo

  class Application < Rails::Application
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %w(#{config.root}/app/concerns #{config.root}/app/authorizers #{config.root}/app/presenters)

    # Cache store location
    config.action_controller.cache_store = [:file_store, "#{config.root}/cache"]

    config.i18n.enforce_available_locales = true

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # To set a system-wide default other than :en, create the file config/locale (which is not under version control).
    config.i18n.default_locale = File.exist?("#{config.root}/config/locale") ? File.read("#{config.root}/config/locale").strip.to_sym : :en
    config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.{rb,yml}"]
    config.i18n.load_path += Dir["#{config.root}/plugins/**/config/locales/*.{rb,yml}"]

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Additional precompiled assets
    config.assets.precompile += %w(editor.js editor.css print.css)

    config.generators do |g|
      g.test_framework :rspec
    end

    # TODO remove this when we get to Rails 4.1
    def secrets
      @secrets ||= begin
        path = Rails.root.join('config/secrets.yml')
        if File.exist?(path)
          OpenStruct.new(YAML.load_file(path)[Rails.env])
        else
          envs = ENV.to_a \
                    .select { |(k, _)| %w(SECRET_TOKEN MAPQUEST_API_KEY).include?(k) } \
                    .map    { |(k, v)| [k.downcase, v] }
          OpenStruct.new(Hash[envs])
        end
      end
    end
  end
end
