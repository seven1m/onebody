namespace :deploy do
  namespace :install do
  
    desc 'Install all required server software on Ubuntu'
    task :default do
      prerequisites
      ruby
      rubygems
      rails
      passenger
      dependencies
      mysql
      postfix
    end
    
    desc 'Install Ruby/OneBody prerequisites'
    task :prerequisites do
      sudo 'aptitude update'
      sudo 'aptitude install -y build-essential imagemagick apache2 apache2-dev apache2-mpm-worker apache2-threaded-dev git-core rsync'
    end
    
    desc 'Install Ruby'
    task :ruby, :roles => :web do
      sudo 'aptitude update'
      sudo 'aptitude install -y ruby1.8 ruby1.8-dev'
    end
    
    desc 'Install RubyGems'
    task :rubygems, :roles => :web do
      sudo 'aptitude update'
      sudo 'aptitude install -y libgems-ruby1.8'
      sudo 'ln -sf /usr/bin/ruby1.8 /usr/bin/ruby'
      run 'cd /tmp && wget -nv http://rubyforge.org/frs/download.php/38646/rubygems-1.2.0.tgz && tar xzf rubygems-1.2.0.tgz'
      run 'cd /tmp/rubygems-1.2.0 && sudo ruby setup.rb'
      if run_and_return('gem1.8 --version') =~ /1\.2\.0/
        sudo 'ln -sf /usr/bin/gem1.8 /usr/bin/gem'
      end
      sudo 'gem update --system'
    end
    
    desc 'Install/Update Rails'
    task :rails do
      rails_version = File.read(File.dirname(__FILE__) + '/../../config/environment.rb').match(/RAILS_GEM_VERSION = '(.+?)'/)[1]
      unless run_and_return('gem list rails') =~ Regexp.new(rails_version)
        sudo "gem install -v=#{rails_version} rails --no-rdoc --no-ri"
      end
    end
    
    desc 'Install Passenger'
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
    
    desc 'Install MySQL'
    task :mysql, :roles => :db do
      sudo 'aptitude update'
      sudo 'aptitude install -y mysql-server libmysql-ruby1.8'
      password = HighLine.new.ask('Password for MySQL root user: ') { |q| q.echo = false }
      run "mysqladmin -uroot password \"#{password}\""
    end
    
    desc 'Install Postfix'
    task :postfix, :roles => :web do
      sudo 'aptitude update'
      sudo 'aptitude install -y postfix'
    end
    
    # Configure iptables firewall (assumes iptables already installed)
    # use at your own risk (check templates/iptables.txt before you use this)
    task :firewall, :roles => :web do
      rules = render_erb_template(File.dirname(__FILE__) + '/templates/iptables.txt')
      put rules, "/tmp/iptables.up.rules"
      sudo "mv /tmp/iptables.up.rules /etc/"
      sudo "ruby -e \"d=File.read('/etc/network/interfaces'); exit if d =~ /iptables/; d.gsub!(/(iface lo inet loopback)(\\n)/, '\\1\\2pre-up iptables-restore < /etc/iptables.up.rules\\2'); File.open('/etc/network/interfaces', 'w') { |f| f.write(d) }\""
      puts 'Restart the server for the config to take effect.'
    end
    
    desc 'Install gem dependencies'
    task :dependencies, :roles => :web do
      gems = File.read(File.dirname(__FILE__) + '/../../config/environment.rb').scan(/config\.gem ["']([a-z_\-]+)["'](.*)/i)
      github_gems = gems.select { |g| g[1] =~ /gems\.github\.com/ }
      gems -= github_gems
      sudo "gem install --no-rdoc --no-ri #{github_gems.map { |g| g[0] }.join(' ')} -s http://gems.github.com"
      sudo "gem install --no-rdoc --no-ri #{gems.map { |g| g[0] }.join(' ')}"
    end
    
    # Ruby Enterprise Edition Recipes
    # # # # # # # # # # # # # # # # #
    
    desc 'Install all required server software on Ubuntu, but use Ruby Enterprise Edition instead'
    task :all_with_ruby_ee do
      prerequisites
      ruby_ee
      rails
      dependencies_with_ruby_ee
      mysql
      postfix
    end
    
    desc 'Install Ruby Enterprise Edition'
    task :ruby_ee, :roles => :web do
      sudo 'aptitude install -y libreadline5-dev libmysqlclient-dev'
      run 'cd /tmp && wget -nv http://rubyforge.org/frs/download.php/51100/ruby-enterprise-1.8.6-20090201.tar.gz && tar xzf ruby-enterprise-1.8.6-20090201.tar.gz'
      run 'cd /tmp/ruby-enterprise-1.8.6-20090201 && sudo ruby installer.rb -a /opt/ruby-enterprise'
    end
    
    desc 'Install/Update Rails in Ruby Enterprise Edition'
    task :rails do
      rails_version = File.read(File.dirname(__FILE__) + '/../../config/environment.rb').match(/RAILS_GEM_VERSION = '(.+?)'/)[1]
      unless run_and_return('/opt/ruby-enterprise/bin/gem list rails') =~ Regexp.new(rails_version)
        sudo "/opt/ruby-enterprise/bin/gem install -v=#{rails_version} rails --no-rdoc --no-ri"
      end
    end
    
    desc 'Install gem dependencies in Ruby Enterprise Edition'
    task :dependencies_with_ruby_ee do
      gems = File.read(File.dirname(__FILE__) + '/../../config/environment.rb').scan(/config\.gem ["']([a-z_\-]+)["'](.*)/i)
      github_gems = gems.select { |g| g[1] =~ /gems\.github\.com/ }
      gems -= github_gems
      sudo "/opt/ruby-enterprise/bin/gem install --no-rdoc --no-ri #{github_gems.map { |g| g[0] }.join(' ')} -s http://gems.github.com"
      sudo "/opt/ruby-enterprise/bin/gem install --no-rdoc --no-ri #{gems.map { |g| g[0] }.join(' ')}"
    end

  end
  
  task :cold do
    update
    find_and_execute_task('deploy:install:rails')
    find_and_execute_task('deploy:install:dependencies')
    migrate
    restart
  end
end
