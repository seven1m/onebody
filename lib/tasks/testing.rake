namespace :test do
  
  Rake::Task[:plugins].abandon
  
  Rake::TestTask.new(:plugins => :environment) do |t|
    t.libs << "test"

    if ENV['PLUGIN']
      t.pattern = "plugins/#{ENV['PLUGIN']}/test/**/*_test.rb"
    else
      t.pattern = 'plugins/*/test/**/*_test.rb'
    end

    t.verbose = true
  end
  Rake::Task['test:plugins'].comment = "Run the plugin tests (optionally specify with PLUGIN=name)"
  
end