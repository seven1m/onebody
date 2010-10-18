begin
  SQLITE = Setting.connection.adapter_name == 'SQLite' rescue false
rescue
  SQLITE = OneBodyInfo.new.database_yaml['production']['adapter'] == 'sqlite3'
end

ONEBODY_VERSION = File.read(Rails.root.join('VERSION')).strip
