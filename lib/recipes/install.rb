REE_PATH = 'http://rubyforge.org/frs/download.php/38755/ruby-enterprise-1.8.6-20080621.tar.gz'

namespace :deploy do
  namespace :install do
    desc 'Install server software on Ubuntu'
    task :default do
      prerequisites
      ruby
      passenger
      db_server
    end
    
    desc 'Install server software, including Ruby Enterprise Edition'
    task :ree do
      prerequisites
      ree
      passenger
      db_server
    end
    
    task :prerequisites do
      sudo 'aptitude update'
      sudo 'aptitude install -y build-essential ruby1.8 imagemagick apache2 apache2-dev apache2-mpm-prefork apache2-prefork-dev git-core'
    end
    
    task :ruby, :roles => :web do
      sudo 'aptitude update'
      sudo 'aptitude install -y ruby1.8-dev libgems-ruby1.8 libmysql-ruby1.8'
      sudo 'ln -sf /usr/bin/ruby1.8 /usr/bin/ruby'
      run 'cd /tmp && wget -nv http://rubyforge.org/frs/download.php/38646/rubygems-1.2.0.tgz && tar xzf rubygems-1.2.0.tgz'
      run 'cd /tmp/rubygems-1.2.0 && sudo ruby setup.rb'
      if run_and_return('gem1.8 --version') =~ /1\.2\.0/
        sudo 'ln -sf /usr/bin/gem1.8 /usr/bin/gem'
      end
      sudo 'gem update --system'
      sudo 'gem install rails --no-rdoc --no-ri'
    end
    
    # desc 'Install Ruby Enterprise Edition in place of MRI.'
    # This probably needs some work.
    task :ree, :roles => :web do
      ree_file = REE_PATH.split('/').last
      ree_dir = ree_file.gsub(/\.tar\.gz$/, '')
      run "cd /tmp && wget -nv #{REE_PATH} && tar xzf #{ree_file}"
      sudo "ln -sf /usr/bin/ruby1.8 /usr/bin/ruby"
      sudo "/tmp/#{ree_dir}/installer -a /opt/#{ree_dir}"
      sudo "ln -sf /opt/#{ree_dir}/bin/ruby /usr/bin/ruby"
      sudo "ln -sf /opt/#{ree_dir}/bin/gem /usr/bin/gem"
      sudo 'gem update --system'
    end
    
    task :passenger, :roles => :web do
      gem_name = nil
      send(:sudo, 'gem install passenger --no-rdoc --no-ri') do |channel, stream, data|
        logger.info data, channel[:host]
        if data =~ /select which gem to install/i
          if selection = data.split(/\n/).select { |l| l =~ /\(ruby\)$/ }.first and
            selection =~ /^\s*(\d+)\./
            logger.info "Selecting #{$1}...", channel[:host]
            channel.send_data "#{$1}\n"
          end
        end
        if data =~ /successfully installed (passenger-[\d\.]+)/i
          gem_name = $1
        end
      end
      gems_path = nil
      send(:run, 'gem which rake') do |channel, stream, data|
        data =~ /^(\/.+?)\/rake.+/
        gems_path = $1
      end
      passenger_path = "#{gems_path}/#{gem_name}"
      run "cd #{passenger_path} && sudo rake clean apache2"
      run "echo 'LoadModule passenger_module #{passenger_path}/ext/apache2/mod_passenger.so' | sudo tee /etc/apache2/mods-available/passenger.load"
      run "echo '<IfModule passenger_module>\\n  PassengerRoot #{passenger_path}\\n  PassengerRuby /usr/bin/ruby\\n</IfModule>' | sudo tee /etc/apache2/mods-available/passenger.conf"
      sudo "a2enmod passenger"
      sudo "/etc/init.d/apache2 force-reload"
    end
    
    task :db_server, :roles => :db do
      sudo 'aptitude update'
      sudo 'aptitude install -y mysql-server'
    end

  end
end
