lock '3.2.1'

set :application, 'onebody'
set :repo_url, 'git://github.com/churchio/onebody.git'
set :deploy_to, '/var/www/apps/onebody'

set :linked_files, %w{config/database.yml config/email.yml config/secrets.yml}

set :linked_dirs, %w{log tmp public/system}

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

end
