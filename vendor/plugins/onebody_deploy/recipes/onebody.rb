# OneBody Deploy Tasks
#
# Much of this code was borrowed from Geoffrey Grosenbach's Capistrano screencast.
# http://peepcode.com
#
# Author: Geoffrey Grosenbach http://topfunky.com
#         November 2007
#
# Author: Tim Morgan http://timmorgan.org
#         March 2008

namespace :deploy do
  
  desc 'Starts one or more thin servers running the application as specified in the deploy.rb file.'
  task :start, :roles => :app do
    as = fetch(:runner, 'app')
    via = fetch(:run_method, :sudo)
    count = fetch(:thin_servers, 1)
    port = fetch(:thin_port, 8000)
    env = fetch(:rails_env, 'production')
    cmd = "sh -c 'cd #{current_path} && thin start -d -e #{env} -p #{port} -s #{count} -P #{shared_path}/pids/thin.pid -l #{shared_path}/log/thin.log'"
    invoke_command cmd, :via => via, :as => as
  end
  
  desc 'Stops one or more running thin servers.'
  task :stop, :roles => :app do
    as = fetch(:runner, 'app')
    via = fetch(:run_method, :sudo)
    count = fetch(:thin_servers, 1)
    port = fetch(:thin_port, 8000)
    cmd = "sh -c 'cd #{current_path} && thin stop -p #{port} -s #{count} -P #{shared_path}/pids/thin.pid'"
    invoke_command cmd, :via => via, :as => as
  end
  
end

namespace :onebody do

  namespace :shared do
    task :setup do
      run "mkdir -p #{shared_path}/db/photos"
      run "mkdir -p #{shared_path}/db/publications"
      run "mkdir -p #{shared_path}/db/tasks"
      run "mkdir -p #{shared_path}/config"
      run "mkdir -p #{shared_path}/public"
      run "mkdir -p #{shared_path}/themes"
      unless run_and_return("ls #{shared_path}/config").match(/database\.yml/)
        yml = File.read(File.dirname(__FILE__) + "/templates/database.yml")
        put yml, "#{shared_path}/config/database.yml"
      end
    end
    after 'deploy:setup', 'onebody:shared:setup'
    
    task :update_files do
      run "cp -r #{release_path}/db/tasks/* #{shared_path}/db/tasks/"
      run "cp -r #{release_path}/public/*   #{shared_path}/public/"
      run "cp -r #{release_path}/themes/*   #{shared_path}/themes/"
    end
    after 'deploy:update_code', 'onebody:shared:update_files'
    
    task :create_symlinks do
      %w(config/database.yml db/photos db/publications db/tasks public themes).each do |file|
        run "rm -rf #{release_path}/#{file}"
        run "ln -s #{shared_path}/#{file} #{release_path}/#{file}"
      end
    end
    after 'onebody:shared:update_files', 'onebody:shared:create_symlinks'
  end
  
end

class Capistrano::Configuration
  def render_erb_template(filename)
    template = File.read(filename)
    result   = ERB.new(template).result(binding)
  end
  
  def run_and_return(cmd)
    output = []
    run cmd do |ch, st, data|
      output << data
    end
    return output.to_s
  end
end