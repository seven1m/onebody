if Site.table_exists? and Page.table_exists?
  Site.each do |site|
    site.add_pages
  end
end
