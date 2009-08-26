# Convenience for script/console so that default site is already set as current site
if $0 == 'irb'
  Site.current = Site.find(1)
  puts 'Sites:'
  puts '  id    name                                                         host'
  puts '  ----- ------------------------------------------------------------ -----------------------------'
  puts Site.all.map { |s| "#{s.default? ? '*' : ' '} #{s.id.to_s.ljust 5} #{s.name.ljust(60)[0...60]} #{s.host}" }.join("\n")
  def use(id)
    Site.current = Site.find(id)
    puts "Set Site.current to <#{Site.current.name}>"
    true
  end
  puts 'Type "use ID" to change selected site...'
end
