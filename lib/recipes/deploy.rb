namespace :deploy do
  
  task :copy_logos do
    run "if [ -e #{previous_release}/public/images ]; then cp #{previous_release}/public/images/logo* #{current_release}/public/images/; fi"
  end
  after 'deploy:update_code', 'deploy:copy_logos'
  
  task :copy_assets do
    run "if [ -e #{previous_release}/public/assets ]; then cp #{previous_release}/public/assets/* #{current_release}/public/assets/; fi"
  end
  after 'deploy:update_code', 'deploy:copy_assets'

  task :copy_custom_themes do
    run "if [ -e #{previous_release}/themes/custom ]; then cp #{previous_release}/themes/custom/* #{current_release}/themes/custom/; fi"
  end
  after 'deploy:update_code', 'deploy:copy_custom_themes'
  
end
