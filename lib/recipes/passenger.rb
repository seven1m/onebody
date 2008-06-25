namespace :deploy do
  
  desc 'Restart app.'
  task :restart, :roles => :web do
    # TODO: touch restart.txt
  end
  
end
