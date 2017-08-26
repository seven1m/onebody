PLUGIN_HOOKS = {} # rubocop:disable Style/MutableConstant

def PLUGIN_HOOKS.register(hook_name, partial_path)
  PLUGIN_HOOKS[hook_name.to_sym] ||= []
  PLUGIN_HOOKS[hook_name.to_sym] << partial_path
end

Dir["#{Rails.root}/plugins/**/config/environment.rb"].each do |path|
  require path.sub(/\.rb$/, '')
end
