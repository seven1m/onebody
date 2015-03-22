SETTINGS = {}

error_class = defined?(Mysql2) ? Mysql2::Error : PG::Error

begin
  Setting.update_all if Setting.table_exists?
rescue error_class
  # no connection probably
end
