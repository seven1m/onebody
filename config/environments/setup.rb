def random_chars(length)
  (1..length).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
end

config.action_controller.session_store = :cookie_store
config.action_controller.session = { :session_key => "_setup_session", :secret => random_chars(50) }
config.frameworks -= [:active_record]
config.cache_classes = false
config.whiny_nils = false
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching = false
config.action_view.cache_template_extensions = false
config.action_view.debug_rjs = true
config.action_mailer.raise_delivery_errors = false
#require 'rails/builtin/rails_info/rails/info' # FIXME: need right path

File.delete(File.join(RAILS_ROOT, 'setup-authorized-ip')) if File.exists? File.join(RAILS_ROOT, 'setup-authorized-ip')
File.open(File.join(RAILS_ROOT, 'setup-secret'), 'w') { |f| f.write random_chars(50) }
