if RAILS_ENV == 'test'
  SETTINGS = YAML::load(File.open(File.join(RAILS_ROOT, 'test/settings.yml'))) 
elsif Setting.table_exists?
  SETTINGS = {}
  Setting.load_settings
else # so intermediate migrations can run during setup
  SETTINGS = {}
  %w(name features url email services contact access).each { |s| SETTINGS[s] = {} }
end