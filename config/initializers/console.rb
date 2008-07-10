# Convenience for script/console so that default site is already set as current site
if $0 == 'irb'
  Site.current = Site.find(1)
  puts 'Site.current set to Default Site'
end
