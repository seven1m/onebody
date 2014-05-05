namespace :deploy do

  desc 'Restart app (Passenger).'
  task :restart, roles: :web do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task(:start) do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task(:stop) do
  end

end
