error_class = defined?(Mysql2) ? Mysql2::Error : PG::Error

begin
  if Site.table_exists? and Page.table_exists?
    Site.each do |site|
      site.add_pages
    end
  end
rescue error_class
  # no connection probably
end
