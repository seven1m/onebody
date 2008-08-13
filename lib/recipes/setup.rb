namespace :deploy do

  task :before_setup do
    sudo "mkdir -p #{deploy_to}"
    sudo "chown #{user}:#{user} #{deploy_to}"
  end
  
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
      run "mkdir -p #{shared_path}/themes"
    end
    after 'deploy:setup', 'deploy:shared:setup'

    desc 'Create MySQL database and grant user privileges'
    task :mysql, :roles => :db do
      run "mysql -u root -e \"create database onebody; grant all on onebody.* to onebody@localhost identified by '#{get_db_password}'\""
      yml = render_erb_template(File.dirname(__FILE__) + '/templates/database.yml')
      put yml, "#{shared_path}/config/database.yml"
    end
    after 'deploy:shared:setup', 'deploy:shared:mysql'
    
    desc 'Point certain OneBody globals to the shared path'
    task :point_db_dirs do
      rb = render_erb_template(File.dirname(__FILE__) + '/templates/links.rb')
      put rb, "#{release_path}/config/initializers/links.rb"
    end
    after 'deploy:update_code', 'deploy:shared:point_db_dirs'
    
    desc 'Copy public files to the shared public path'
    task :update_public_files do
      run "cp -r #{release_path}/public/* #{shared_path}/public/"
    end
    after 'deploy:update_code', 'deploy:shared:update_public_files'

    desc 'Symlink certain files to the shared path'
    task :create_symlinks do
      run "ln -sf #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    end
    after 'deploy:shared:update_public_files', 'deploy:shared:create_symlinks'
    
    desc 'Install/update gem dependencies'
    task :update_dependencies do
      run "cd #{release_path} && sudo rake gems:install"
    end
    after 'deploy:shared:create_symlinks', 'deploy:shared:update_dependencies'

  end


end
