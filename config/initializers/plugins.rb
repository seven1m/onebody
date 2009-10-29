PLUGIN_HOOKS = {}

def PLUGIN_HOOKS.register(template_path, hook_name, partial_path)
  PLUGIN_HOOKS[template_path] ||= {}
  PLUGIN_HOOKS[template_path][hook_name.to_sym] ||= []
  PLUGIN_HOOKS[template_path][hook_name.to_sym] << partial_path
end

Dir["#{Rails.root}/plugins/**/config/environment.rb"].each do |path|
  require path.sub(/\.rb$/, '')
end
