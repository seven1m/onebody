namespace :deploy do
  
  task :copy_logos do
    run "cp #{previous_release}/public/images/logo* #{current_release}/public/images/"
  end
  after 'deploy:update_code', 'deploy:copy_logos'

end