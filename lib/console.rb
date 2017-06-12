class ConsoleRailtie < Rails::Railtie
  console do
    Site.current = Site.find(1)
    Rails::ConsoleMethods.use
  end
end

module Rails
  module ConsoleMethods
    def use(id = nil)
      Site.current = Site.find(id) if id
      puts 'Sites:'
      puts '  id    name                                     host'
      puts '  ----- ---------------------------------------- ------------------------------'
      Site.all.each do |site|
        next if id && site.id != id
        puts "#{site == Site.current ? '*' : ' '} #{site.id.to_s.ljust 5} #{site.name.ljust(40)[0...40]} #{site.host.ljust(30)[0...30]}"
      end
      puts
      puts 'Type "use ID" to change selected site...'
      true
    end
    module_function :use
  end
end
