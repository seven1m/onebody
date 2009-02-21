PLUGIN_HOOKS = {
  :more_page => []
}

# Only place as of yet that plugins can inject html: on the "More" tab.
# Looks something like this:
#                             # partial path,            condition proc (optional)
# PLUGIN_HOOKS[:more_page] << ['checkin/more_page_link', Proc.new { |c| c.instance_eval('@logged_in').checkin_access? }]

Dir[Rails.root + 'plugins/*/hooks.rb'].each do |hooks_file|
  plugin = hooks_file.match(/plugins\/(.+?)\/hooks\.rb$/)[1]
  if File.exist?(Rails.root + 'plugins/' + plugin + '/enable')
    load(hooks_file)
  end
end
