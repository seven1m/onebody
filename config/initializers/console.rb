if defined?(IRB)
  Site.current = Site.find(1)
  def use(id=nil)
    Site.current = Site.find(id) if id
    puts 'Sites:'
    puts '  id    name                                     host'
    puts '  ----- ---------------------------------------- ------------------------------'
    Site.all.each do |site|
      next if id and site.id != id
      puts "#{site == Site.current ? '*' : ' '} #{site.id.to_s.ljust 5} #{site.name.ljust(40)[0...40]} #{site.host.ljust(30)[0...30]}"
    end
    true
  end
  use
  puts 'Type "use ID" to change selected site...'
end
