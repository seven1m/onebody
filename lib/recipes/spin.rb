namespace :deploy do
  
  desc 'Restart App in Passenger.'
  task :restart, :roles => :web do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  task(:start) do
    puts "\nYou will need to manually start Apache."
  end
  
  task(:stop) do
    puts "\nYou will need to manually stop Apache."
  end
  
end
