require 'open-uri'

namespace :deploy do

  namespace :install do

    desc 'Deploy the newest release, install Rails, gem dependencies, and migrate the database.'
    task :default do
      update
      find_and_execute_task('deploy:install:rails')
      find_and_execute_task('deploy:install:dependencies')
      migrate
      restart
    end

    desc 'Install/Update Rails'
    task :rails do
      rails_version = File.read(File.dirname(__FILE__) + '/../../config/environment.rb').match(/RAILS_GEM_VERSION = '(.+?)'/)[1]
      unless run_and_return('gem list rails') =~ Regexp.new(rails_version)
        run "gem install -v=#{rails_version} rails --no-rdoc --no-ri"
      end
    end

    desc 'Install gem dependencies'
    task :dependencies, :roles => :web do
      run "cd #{release_path}; gem install mysql && rake gems:install"
    end

  end

  namespace :upgrade do

    desc 'Deploy the newest release, upgrade Rails, gem dependencies, and migrate the database.'
    task :default do
      # for the timebeing, this does nothing different than the deploy:install recipe
    end
    after 'deploy:upgrade', 'deploy:install'

  end

end
