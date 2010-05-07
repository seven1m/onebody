namespace :onebody do

  task :find_missing_tests do
    root = File.dirname(__FILE__) + '/../..'
    Dir["#{root}/app/models/*.rb"].each do |file|
      test = "#{File.split(file).last.split('.').first}_test.rb"
      unless File.exist?("#{root}/test/unit/#{test}")
        puts test
      end
    end
  end

end
