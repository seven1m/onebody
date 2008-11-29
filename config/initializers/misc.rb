PEOPLE_ATTRIBUTES_SHOWABLE_ON_HOMEPAGE = %w(website business_name business_description business_phone business_email business_website activities interests music tv_shows movies books quotes about testimony )

begin
  SQLITE = Setting.connection.adapter_name == 'SQLite' rescue false
rescue
  SQLITE = OneBodyInfo.new.database_yaml['production']['adapter'] == 'sqlite3'
end

ONEBODY_VERSION = File.read(File.join(RAILS_ROOT, 'VERSION')).strip
