
module Comatose

  VERSION = "0.8"

  # DEPRECATED
  # Loads extensions from RAILS_ROOT/lib/comatose/*.rb
  def self.load_extensions
    Dir[File.join(RAILS_ROOT, 'lib', 'comatose', '*.rb')].each do |path|
      require "comatose/#{File.basename(path)}"
    end
  end

end

require 'comatose/configuration'
require 'comatose/drops'

require 'dispatcher' unless defined?(::Dispatcher)
::Dispatcher.to_prepare :comatose do
    base = File.dirname(__FILE__)
    # Load these on every request (in dev mode)
    load "#{base}/comatose/page.rb"
    load "#{base}/comatose/admin_controller.rb"
    load "#{base}/comatose/admin_helper.rb"
    load "#{base}/comatose/controller.rb"
    # These will only be loaded once (in any mode)
    require 'support/inline_rendering'
    require 'comatose/processing_context'
    require 'comatose/page_wrapper'
    # Define the base classes
    class ComatoseAdminController < Comatose::AdminController
      unloadable
    end
    class ComatoseController < Comatose::Controller
      unloadable
    end
    Comatose.config.after_setup.call
end
