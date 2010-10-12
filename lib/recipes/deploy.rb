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
      run "mkdir -p #{shared_path}/themes"
      run "mkdir -p #{shared_path}/plugins"
      run "mkdir -p #{shared_path}/initializers"
    end
    after 'deploy:setup', 'deploy:shared:setup'

  end

  task :create_database do
    unless ENV['SKIP_DB_SETUP']
      mysql_root_password = HighLine.new.ask('MySQL ROOT password: ') { |q| q.echo = false }
      p = mysql_root_password.empty? ? '' : "-p#{mysql_root_password}"
      run "mysql -uroot #{p} -e \"create database if not exists onebody; grant all on onebody.* to onebody@localhost identified by '#{get_db_password}';\""
      yml = render_erb_template(File.dirname(__FILE__) + '/templates/database.yml')
      put yml, "#{shared_path}/config/database.yml"
    end
  end
  after 'deploy:setup', 'deploy:create_database'

  desc 'Install/Update Rails'
  task :rails do
    run "ver=`grep \"RAILS_GEM_VERSION\" #{release_path}/config/environment.rb | cut -d \\\\' -f 2` && " + \
        "lst=`gem list rails | fgrep $ver`; " + \
        "if [[ $lst == \"\" ]]; then " + \
        "  gem install rails -v $ver --no-rdoc --no-ri; " + \
        "fi"
  end
  after 'deploy:update_code', 'deploy:rails'

  desc 'Install mysql gem'
  task :mysqlgem, :roles => :web do
    run "lst=`gem list mysql`; " + \
        "if [[ $lst == \"\" ]]; then " + \
        "  gem install mysql --no-rdoc --no-ri; " + \
        "fi"
  end
  after 'deploy:rails', 'deploy:mysqlgem'

  desc 'Install gem dependencies'
  task :gemdeps, :roles => :web do
    run "cd #{release_path} && rake gems:install"
  end
  after 'deploy:rails', 'deploy:gemdeps'

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
