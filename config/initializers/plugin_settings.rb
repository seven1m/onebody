WhiteListHelper.tags.merge %w(u)

Comatose.configure do |config|
  config.admin_title = SETTINGS['name']['site']
  config.admin_sub_title = 'Page Editor'
end