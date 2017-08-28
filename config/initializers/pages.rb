begin
  Site.each(&:add_pages) if Site.table_exists? && Page.table_exists?
rescue Mysql2::Error
  # no connection probably
end
