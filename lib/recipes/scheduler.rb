namespace :deploy do

  namespace :scheduler do
    
    desc 'Start the Scheduler daemon.'
    task :start, :roles => :web do
      run "cd #{current_path} && script/scheduler start production"
    end
    
    desc 'Stop the Scheduler daemon.'
    task :stop, :roles => :web do
      # stop any running instance in case we forgot to do so before changing the symlink
      run "ps aux | ruby -e \"STDIN.read.select { |p| p =~ /script.scheduler start production/ }.each { |p| Process.kill('HUP', p.split[1].to_i) }\"" rescue nil
    end
    
    desc 'Restart the Scheduler daemon.'
    task :restart, :roles => :web do
      stop
      start
    end
    
  end

end
