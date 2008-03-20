config.action_controller.session_store = :cookie_store
random_secret = (1..50).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
config.action_controller.session = { :session_key => "_setup_session", :secret => random_secret }
config.frameworks -= [:active_record]
config.cache_classes = false
config.whiny_nils = false
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching = false
config.action_view.cache_template_extensions = false
config.action_view.debug_rjs = true
config.action_mailer.raise_delivery_errors = false
require 'rails/railties/builtin/rails_info/rails/info'