config.action_controller.session_store = :cookie_store
config.action_controller.session = { :session_key => "_setup_session", :secret => ActiveSupport::SecureRandom.hex(50) }
config.frameworks -= [:active_record]
config.cache_classes = false
config.whiny_nils = false
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching = false
config.action_view.debug_rjs = true
config.action_mailer.raise_delivery_errors = false
require RAILTIES_PATH + '/builtin/rails_info/rails/info'

File.delete(File.join(RAILS_ROOT, 'setup-authorized-ip')) if File.exists? File.join(RAILS_ROOT, 'setup-authorized-ip')
File.open(File.join(RAILS_ROOT, 'setup-secret'), 'w') { |f| f.write ActiveSupport::SecureRandom.hex(50) }
