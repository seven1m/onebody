# delete a controller and its associated views, helpers, and tests

task :delete_controller do
  name = ENV['NAME']
  `cd #{RAILS_ROOT} && git rm app/controllers/#{name}_controller.rb`
  `cd #{RAILS_ROOT} && git rm -r app/views/#{name}`
  `cd #{RAILS_ROOT} && git rm test/functional/#{name}_controller_test.rb`
end
