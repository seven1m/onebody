PLUGIN_VIEW_PATHS = []
Dir[Rails.root + '/plugins/*'].each do |plugin|
  if File.exist?(plugin + '/enable')
    puts '===============', plugin
    PLUGIN_VIEW_PATHS << File.expand_path(plugin + '/views')
  end
end
