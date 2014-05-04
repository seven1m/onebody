namespace :deploy do

  task :chown_deploy_dir do
    sudo "mkdir -p #{deploy_to}"
    sudo "chown #{user}:#{user} #{deploy_to}"
  end
  before 'deploy:setup', 'deploy:chown_deploy_dir'

  namespace :shared do

    desc 'Setup shared directories'
    task :setup do
      Dir[File.dirname(__FILE__) + '/../../db/**/*'].each do |path|
        next if path =~ /migrate/
        next unless File.directory?(path)
        run "mkdir -p #{shared_path}/db/#{path.split('db/').last}"
      end
      run "mkdir -p #{shared_path}/config"
      run "mkdir -p #{shared_path}/public"
      run "mkdir -p #{shared_path}/plugins"
      run "mkdir -p #{shared_path}/initializers"
    end
    after 'deploy:setup', 'deploy:shared:setup'

  end

  desc 'Install gem dependencies'
  task :bundler, roles: :web do
    run "cd #{release_path} && bundle install --without development --without test"
  end
  after 'deploy:update_code', 'deploy:bundler'

  task :update_links_and_plugins do
    rb = render_erb_template(File.dirname(__FILE__) + '/templates/links.rb')
    put rb, "#{release_path}/config/initializers/links.rb"
    commands = [
      "ln -sf #{shared_path}/config/database.yml #{release_path}/config/database.yml",
      "if [ -e #{shared_path}/config/email.yml ]; then ln -sf #{shared_path}/config/email.yml #{release_path}/config/email.yml; fi",
      "rm -rf #{release_path}/public/assets && ln -s #{shared_path}/public/assets #{release_path}/public/assets",
      "cd #{shared_path}/plugins; if [ \"$(ls -A)\" ]; then rsync -a * #{release_path}/plugins/; fi",
      "cd #{shared_path}/initializers; if [ \"$(ls -A)\" ]; then rsync -a * #{release_path}/config/initializers/; fi",
      "cd #{release_path}; if [[ `which whenever` != '' ]]; then whenever -w RAILS_ENV=production; fi"
    ]
    run commands.join('; ')
  end
  after 'deploy:update_code', 'deploy:update_links_and_plugins'

end
