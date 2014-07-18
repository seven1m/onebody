SETTINGS = {}

begin
  Setting.update_all if Setting.table_exists?
rescue Mysql2::Error
  # no connection probably
end
