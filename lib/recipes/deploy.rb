namespace :deploy do
  
  task :copy_logos do
    run "if [ -e #{previous_release}/public/images ]; then cp #{previous_release}/public/images/logo* #{current_release}/public/images/; fi"
  end
  after 'deploy:update_code', 'deploy:copy_logos'

end
