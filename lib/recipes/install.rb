require 'open-uri'

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
      sudo 'aptitude install -y build-essential imagemagick apache2 apache2-dev apache2-mpm-worker apache2-threaded-dev git-core rsync libxml2-dev libxslt-dev libcurl4-gnutls-dev'
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
      run 'cd /tmp && wget -nv http://rubyforge.org/frs/download.php/60718/rubygems-1.3.5.tgz && tar xzf rubygems-1.3.5.tgz'
      run 'cd /tmp/rubygems-1.3.5 && sudo ruby setup.rb'
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

    desc 'Install Passenger (set APACHE_CONFIG=true to enable module in Apache)'
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
      if ENV['APACHE_CONFIG']
        run "echo 'LoadModule passenger_module #{passenger_path}/ext/apache2/mod_passenger.so' | sudo tee /etc/apache2/mods-available/passenger.load"
        run "echo '<IfModule passenger_module>\\n  PassengerRoot #{passenger_path}\\n  PassengerRuby /usr/bin/ruby\\n</IfModule>' | sudo tee /etc/apache2/mods-available/passenger.conf"
        sudo "a2enmod passenger"
        sudo "/etc/init.d/apache2 force-reload"
      end
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
      gems = File.read(File.dirname(__FILE__) + '/../../config/environment.rb').scan(/config\.gem ["']([a-z0-9_\-]+)["'](.*)/i)
      github_gems = gems.select { |g| g[1] =~ /gems\.github\.com/ }
      gems -= github_gems
      sudo "gem install --no-rdoc --no-ri #{gems.map { |g| g[0] }.join(' ')}"
      sudo "gem install --no-rdoc --no-ri #{github_gems.map { |g| g[0] }.join(' ')} -s http://gems.github.com"
    end

    # Ruby Enterprise Edition Recipes
    # # # # # # # # # # # # # # # # #

    namespace :ree do

      desc 'Install all required server software on Ubuntu, with Ruby Enterprise Edition'
      task :default do
        find_and_execute_task('deploy:install:prerequisites')
        ruby
        rails
        dependencies
        find_and_execute_task('deploy:install:mysql')
        find_and_execute_task('deploy:install:postfix')
      end

      desc 'Install Ruby Enterprise Edition'
      task :ruby, :roles => :web do
        sudo 'aptitude install -y libreadline5-dev libmysqlclient-dev'
        url = open('http://www.rubyenterpriseedition.com/download.html').read.match(%r{http://rubyforge\.org/frs/download\.php/[^"]+}).to_s
        filename = url.split('/').last
        run "cd /tmp && wget -nv #{url} && tar xzf #{filename}"
        directory = filename.sub(/\.tar\.gz/, '')
        run "cd /tmp/#{directory} && sudo ruby installer.rb -a /opt/ruby-enterprise"
      end

      desc 'Install Passenger (set APACHE_CONFIG=true to enable module in Apache)'
      task :passenger, :roles => :web do
        gem_name = nil
        send(:sudo, '/opt/ruby-enterprise/bin/gem install passenger --no-rdoc --no-ri') do |channel, stream, data|
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
        gems_path = '/opt/ruby-enterprise/lib/ruby/gems/1.8/gems'
        passenger_path = "#{gems_path}/#{gem_name}"
        run "cd #{passenger_path} && sudo rake clean apache2"
        if ENV['APACHE_CONFIG']
          run "echo 'LoadModule passenger_module #{passenger_path}/ext/apache2/mod_passenger.so' | sudo tee /etc/apache2/mods-available/passenger.load"
          run "echo '<IfModule passenger_module>\\n  PassengerRoot #{passenger_path}\\n  PassengerRuby /opt/ruby-enterprise/bin/ruby\\n</IfModule>' | sudo tee /etc/apache2/mods-available/passenger.conf"
          sudo "a2enmod passenger"
          sudo "/etc/init.d/apache2 force-reload"
        end
      end

      desc 'Install/Update Rails in Ruby Enterprise Edition'
      task :rails do
        rails_version = File.read(File.dirname(__FILE__) + '/../../config/environment.rb').match(/RAILS_GEM_VERSION = '(.+?)'/)[1]
        unless run_and_return('/opt/ruby-enterprise/bin/gem list rails') =~ Regexp.new(rails_version)
          sudo "/opt/ruby-enterprise/bin/gem install -v=#{rails_version} rails --no-rdoc --no-ri"
        end
      end

      desc 'Install gem dependencies in Ruby Enterprise Edition'
      task :dependencies do
        gems = File.read(File.dirname(__FILE__) + '/../../config/environment.rb').scan(/config\.gem ["']([a-z0-9_\-]+)["'](.*)/i)
        github_gems = gems.select { |g| g[1] =~ /gems\.github\.com/ }
        gems -= github_gems
        sudo "/opt/ruby-enterprise/bin/gem install --no-rdoc --no-ri #{gems.map { |g| g[0] }.join(' ')}"
        sudo "/opt/ruby-enterprise/bin/gem install --no-rdoc --no-ri #{github_gems.map { |g| g[0] }.join(' ')} -s http://gems.github.com"
      end

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
