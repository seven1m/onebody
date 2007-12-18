# Settings are read from the database if possible.
SETTINGS = {}

# In the Test environment, the settings are read from the test/settings.yml file
if RAILS_ENV == 'test'
  fixtures = YAML::load(File.open(File.join(RAILS_ROOT, 'test/fixtures/settings.yml')))
  Setting.load_settings_from_array fixtures.map { |i, f| [f['section'], f['name'], f['value']] }
  Setting.update_template_view_paths

# If the environment is fully loaded, the database exists, and the settings table exists,
# then they're read from the database
elsif (Setting.connection rescue nil) and Setting.table_exists?
  Setting.load_settings
  
# If the database and/or table isn't avaialable, all settings are set to nil
# so exceptions won't be raised all over the place.
else
  %w(name features url email services contact access).each { |s| SETTINGS[s] = {} }
  SETTINGS['appearance'] = {'theme' => 'aqueouslight'}

end