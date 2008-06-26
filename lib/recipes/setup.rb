namespace :deploy do

  task :before_setup do
    sudo "mkdir -p #{deploy_to}"
    sudo "chown #{user}:#{user} #{deploy_to}"
  end
  
  namespace :shared do
  
    # TODO: move this task to another namespace
    task :update_rails do
      rails_version = File.read(File.dirname(__FILE__) + '/../../config/environment.rb').match(/RAILS_GEM_VERSION = '(.+?)'/)[1]
      unless run_and_return('gem list rails') =~ Regexp.new(rails_version)
        sudo "gem install -v=#{rails_version} rails --no-rdoc --no-ri"
      end
    end
    after 'deploy:update_code', 'deploy:shared:update_rails'
    
    task :setup do
      run "mkdir -p #{shared_path}/db/photos/families"
      run "mkdir -p #{shared_path}/db/photos/groups"
      run "mkdir -p #{shared_path}/db/photos/people"
      run "mkdir -p #{shared_path}/db/photos/pictures"
      run "mkdir -p #{shared_path}/db/photos/recipes"
      run "mkdir -p #{shared_path}/db/publications"
      run "mkdir -p #{shared_path}/db/attachments"
      run "mkdir -p #{shared_path}/db/tasks"
      run "mkdir -p #{shared_path}/config"
      run "mkdir -p #{shared_path}/public"
      run "mkdir -p #{shared_path}/themes"
    end
    after 'deploy:setup', 'deploy:shared:setup'

    task :mysql, :roles => :db do
      run "mysql -u root -e \"create database onebody; grant all on onebody.* to onebody@localhost identified by '#{db_password}'\""
      yml = render_erb_template(File.dirname(__FILE__) + '/templates/database.yml')
      put yml, "#{shared_path}/config/database.yml"
    end
    after 'deploy:shared:setup', 'deploy:shared:mysql'
    
    task :point_db_dirs do
      rb = render_erb_template(File.dirname(__FILE__) + '/templates/links.rb')
      put rb, "#{release_path}/config/initializers/links.rb"
    end
    after 'deploy:update_code', 'deploy:shared:point_db_dirs'
    
    task :update_public_files do
      run "cp -r #{release_path}/public/* #{shared_path}/public/"
    end
    after 'deploy:update_code', 'deploy:shared:update_public_files'

    task :update_tasks do
      run "cp -r #{release_path}/db/tasks/* #{shared_path}/db/tasks/"
    end
    after 'deploy:shared:update_public_files', 'deploy:shared:update_tasks'
    
    task :create_symlinks do
      %w(config/database.yml public).each do |file|
        run "rm -rf #{release_path}/#{file}"
        run "ln -s #{shared_path}/#{file} #{release_path}/#{file}"
      end
    end
    after 'deploy:shared:update_tasks', 'deploy:shared:create_symlinks'
    
    # TODO: move this task to another namespace
    task :update_dependencies do
      run "cd #{release_path} && sudo rake gems:install"
    end
    after 'deploy:shared:create_symlinks', 'deploy:shared:update_dependencies'

  end


end
