namespace :deploy do

  namespace :scheduler do
    
    desc 'Start the Scheduler daemon.'
    task :start, :roles => :web do
      run "cd #{current_path} && script/scheduler start production"
    end
    
    desc 'Stop the Scheduler daemon.'
    task :stop, :roles => :web do
      # stop any running instance in case we forgot to do so before changing the symlink
      run_and_return("ps aux | grep '[s]cript/scheduler start production'").split("\n").each do |match|
        pid = match.split[1]
        run "kill -HUP #{pid}"
      end
    end
    
    desc 'Restart the Scheduler daemon.'
    task :restart, :roles => :web do
      stop
      start
    end
    
  end

end
