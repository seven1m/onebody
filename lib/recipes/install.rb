namespace :deploy do
  namespace :install do
  
    desc 'Install all required server software on Ubuntu'
    task :default do
      prerequisites
      ruby
      rubygems
      rails
      passenger
      mysql
      postfix
    end
    
    desc 'Install Ruby/OneBody prerequisites'
    task :prerequisites do
      sudo 'aptitude update'
      sudo 'aptitude install -y build-essential imagemagick apache2 apache2-dev apache2-mpm-prefork apache2-prefork-dev git-core'
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
    after 'deploy:update_code', 'deploy:install:rails'
    
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
      sudo 'echo'
      run "cd #{release_path}; sudo rake gems:install"
    end
    after 'deploy:update_code', 'deploy:install:dependencies'

  end
end
