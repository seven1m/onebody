namespace :onebody do

  # prereqs:
  # sudo aptitude install ruby irb1.8 rake rdoc1.8 ruby1.8-dev mysql-server postfix courier-pop libmysql-ruby1.8 build-essential imagemagick apache2 apache2-threaded-dev apache2-mpm-worker apache2-threaded-dev libxml2-dev libxslt1-dev libcurl4-gnutls-dev libhttp-access2-ruby1.8 makepasswd

  desc 'Build a Debian package for installation.'
  task :deb do
  
    VERSION = File.read(RAILS_ROOT + '/VERSION').strip
    FileUtils.rm_rf(RAILS_ROOT + '/pkg')
    FileUtils.mkdir_p(RAILS_ROOT + '/pkg/var/lib/onebody')
    FileUtils.mkdir_p(RAILS_ROOT + '/pkg/usr/share/doc/onebody')
    FileUtils.mkdir_p(RAILS_ROOT + '/pkg/usr/bin')
    File.open(RAILS_ROOT + '/pkg/usr/share/doc/onebody/copyright', 'w') do |license|
      license.write(<<EOF)
OneBody

Copyright 2008-2009, Tim Morgan <tim@timmorgan.org)

The home page of OneBody is at: http://beonebody.com

The entire code base may be distributed under the terms of the GNU General
Public License (GPL), which appears immediately below.

See /usr/share/common-licenses/GPL-3
EOF
    end
    FileUtils.mkdir_p(RAILS_ROOT + '/pkg/DEBIAN')
    File.open(RAILS_ROOT + '/pkg/DEBIAN/control', 'w') do |control|
      control.write(<<EOF)
Package: onebody
Version: #{VERSION}-1
Section: web
Priority: optional
Architecture: all
Depends: ruby (>= 1.8), irb1.8, rake, rdoc1.8, ruby1.8-dev, mysql-server, postfix, courier-pop, libmysql-ruby1.8, build-essential, imagemagick, apache2, apache2-threaded-dev, apache2-mpm-worker, apache2-threaded-dev, libxml2-dev, libxslt1-dev, libcurl4-gnutls-dev, libhttp-access2-ruby1.8, makepasswd
Maintainer: Tim Morgan <tim@timmorgan.org>
Homepage: http://beonebody.com
Description: Web Application
 This is a Rails-based web application for hosting community-focused
 social network. This package installs the app and a full Ruby on Rails
 stack, plus Apache, Postfix, and other needed libraries for hosting a
 community site.
EOF
    end
    File.open(RAILS_ROOT + '/pkg/DEBIAN/postinst', 'w') do |postinst|
      postinst.write(<<EOF)
#!/bin/bash

if [[ `which gem` = "" ]] || [[ `gem -v` < "1.3.5" ]]; then
  echo "Installing/Upgrading RubyGems..."
  cd /tmp && wget -nv http://rubyforge.org/frs/download.php/60718/rubygems-1.3.5.tgz && tar xzf rubygems-1.3.5.tgz && rm rubygems-1.3.5.tgz
  cd /tmp/rubygems-1.3.5 && ruby setup.rb && cd /tmp
  rm -rf /tmp/rubygems-1.3.5
  echo "Symlinking /usr/bin/gem1.8 at /usr/bin/gem..."
  ln -sf /usr/bin/gem1.8 /usr/bin/gem
fi

echo "Installing required gems..."
gem install rdoc
gem install rack highline builder sqlite3-ruby chronic
gem install javan-whenever -s http://gems.github.com

echo "Symlinking /usr/bin/irb1.8 at /usr/bin/irb..."
ln -sf /usr/bin/irb1.8 /usr/bin/irb

echo "Building native extensions for unpacked gems..."
cd /var/lib/onebody && rake gems:build

if [ \\! -e "/home/onebody" ]; then
  echo
  echo "============================================================================="
  echo " OneBody files are installed. Now run the following command to finish setup: "
  echo "                         sudo /usr/bin/setup-onebody                         "
  echo "============================================================================="
fi
EOF
    end
    FileUtils.chmod(0755, RAILS_ROOT + '/pkg/DEBIAN/postinst')
    File.open(RAILS_ROOT + '/pkg/DEBIAN/prerm', 'w') do |prerm|
      prerm.write(<<EOF)
#!/bin/bash

rm -rf /var/lib/onebody/db
rm -rf /var/lib/onebody/config
rm -rf /var/lib/onebody/log
rm -rf /var/lib/onebody/vendor

EOF
    end
    FileUtils.chmod(0755, RAILS_ROOT + '/pkg/DEBIAN/prerm')
    File.open(RAILS_ROOT + '/pkg/usr/bin/setup-onebody', 'w') do |setup|
      setup.write(<<EOF)
#!/bin/bash

echo "This will setup the necessary components for running OneBody, including:"
echo " * create a user called 'onebody'"
echo " * create a database called 'onebody'"
echo " * configure a catchall email address in Postfix and a POP account"
echo " * add scheduled tasks to the cron for user 'onebody'"
echo " * install Phusion Passenger from source and add the module to Apache"
echo
echo "You will be asked at each step to confirm."
echo
echo "Let's get started..."

echo
read -p "Create a user 'onebody'? [y] " answer
if [ "$answer" = "" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ] || [ "$answer" = "Y" ] || [ "$answer" = "YES" ]; then
  echo "Creating user 'onebody'..."
  onebodypass=`makepasswd --chars=15`
  useradd --create-home -s /usr/sbin/nologin -p$onebodypass onebody
  chown -R onebody:onebody /var/lib/onebody
fi

echo
read -p "Create the 'onebody' database? [y] " answer
if [ "$answer" = "" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ] || [ "$answer" = "Y" ] || [ "$answer" = "YES" ]; then
  echo "Configuring the database..."
  while true; do
    echo "Enter the root password for your MySQL server instance below."
    echo "This will be used to create a new database called 'onebody' and a new MySQL user called 'onebody'."
    read -p "MySQL 'root' Password [none]: " rootpass
    userpass=`makepasswd --chars=15`
    echo "production:\n  adapter: mysql\n  database: onebody\n  username: onebody\n  password: $userpass\n  host: localhost" > /var/lib/onebody/config/database.yml
    if [ "$rootpass" != "" ]; then
      rootpass="-p$rootpass"
    fi
    mysql -uroot $rootpass -e "create database onebody; grant all on onebody.* to onebody@localhost identified by '$userpass';"
    if [ "$?" = 0 ]; then break; fi
  done
  cd /var/lib/onebody && sudo -u onebody rake db:migrate RAILS_ENV=production
fi

echo
read -p "Create a catchall address in Postfix? [y] " answer
if [ "$answer" = "" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ] || [ "$answer" = "Y" ] || [ "$answer" = "YES" ]; then
  echo "Configuring email..."
  mkdir /home/onebody/Maildir && chown onebody:onebody /home/onebody/Maildir
  echo "\n\n# config added by OneBody\nhome_mailbox = Maildir/\nluser_relay = onebody\nlocal_recipient_maps =\n# end config added by OneBody\n" >> /etc/postfix/main.cf
  postfix reload
  echo "production:\n  pop:\n    host: localhost\n    username: onebody\n    password: $onebodypass\n  smtp:\n    address: localhost\n    domain: example.com" > /var/lib/onebody/config/email.yml
fi

echo
read -p "Configure scheduled tasks in cron? [y] " answer
if [ "$answer" = "" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ] || [ "$answer" = "Y" ] || [ "$answer" = "YES" ]; then
  echo "Configuring cron..."
  cd /var/lib/onebody && sudo -u onebody whenever -w RAILS_ENV=production
fi

echo
read -p "Install Passenger and setup Apache (requires Apache restart)? [y] " answer
if [ "$answer" = "" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ] || [ "$answer" = "Y" ] || [ "$answer" = "YES" ]; then
  echo "Installing Phusion Passenger and configuring Apache..."
  gem install passenger --no-rdoc --no-ri
  version=`gem list --local | grep passenger | ruby -e "print STDIN.read.match(/\\((.+)\\)/)[1]"`
  passenger_path="/usr/lib/ruby/gems/1.8/gems/passenger-$version"
  cd $passenger_path && rake clean apache2
  echo "LoadModule passenger_module $passenger_path/ext/apache2/mod_passenger.so" > /etc/apache2/mods-available/passenger.load
  echo "<IfModule passenger_module>\n  PassengerRoot $passenger_path\n  PassengerRuby /usr/bin/ruby\n</IfModule>" > /etc/apache2/mods-available/passenger.conf
  a2enmod rewrite
  a2enmod passenger
  invoke-rc.d apache2 force-reload
  echo
  echo "You're almost done! To finish up, Apache just needs to be configured."
  echo "Just create a new virtual host with your DocumentRoot pointing at:"
  echo "  /var/lib/onebody/public"
  echo
  echo "Example:"
  echo
  echo "<VirtualHost *>"
  echo "  ServerName www.myonebodysite.com"
  echo "  DocumentRoot /var/lib/onebody/public"
  echo "</VirtualHost>"
  echo
  echo "Enable your site, restart Apache, and you should be done!"
fi
EOF
    end
    FileUtils.chmod(0755, RAILS_ROOT + '/pkg/usr/bin/setup-onebody')
    File.open(RAILS_ROOT + '/pkg/usr/share/doc/onebody/changelog', 'w') do |changelog|
      versions = []
      File.read(RAILS_ROOT + '/CHANGELOG.markdown').split(/\n/).each do |part|
        if part =~ /^([\d\.]+) \/ ([a-z]+ \d+, \d{4})/i
          date = Date.parse($2) rescue Date.today
          versions << [$1, date, []]
        elsif part =~ /^\* (.+)/ and versions.any?
          versions.last.last << $1
        elsif part =~ /^\*\*Upgrade Note:\*\* (.+)/ and versions.any?
          versions.last.last << 'Upgrade Note: ' + $1
        end
      end
      versions.each do |version, release_date, changes|
        changelog.write("onebody (#{version}-1)\n\n")
        changes.each do |change|
          changelog.write("  * #{change}\n")
        end
        changelog.write("\n  -- Tim Morgan <tim@timmorgan.org>  #{release_date.strftime('%Y-%m-%d')}\n\n")
      end
    end
    File.open(RAILS_ROOT + '/pkg/usr/share/doc/onebody/changelog.Debian', 'w') do |control|
      control.write("onebody Debian maintainer and upstream author are identical.\nTherefore see also normal changelog file for Debian changes.")
    end
    `gzip --best #{RAILS_ROOT}/pkg/usr/share/doc/onebody/changelog`
    `gzip --best #{RAILS_ROOT}/pkg/usr/share/doc/onebody/changelog.Debian`
    `git checkout-index -a -f --prefix=/tmp/onebody/ && mv /tmp/onebody/* #{RAILS_ROOT}/pkg/var/lib/onebody/`
    `cd #{RAILS_ROOT}/pkg/var/lib/onebody && rake gems:unpack:dependencies`
    `cd #{RAILS_ROOT}/pkg/var/lib/onebody && rake rails:freeze:gems`
    `find #{RAILS_ROOT}/pkg/var -name .gitignore | xargs rm`
    `rm #{RAILS_ROOT}/pkg/var/lib/onebody/LICENSE`
    filename = "onebody_#{VERSION}-1_all.deb"
    `fakeroot dpkg-deb --build pkg && mv pkg.deb #{filename}`
    lintian = `lintian #{filename}`
    puts "#{lintian.scan(/^W:/).length} warnings. Run `lintian #{filename}` to see them all."
    if lintian =~ /^E:/
      FileUtils.rm(filename)
      puts 'There were errors:'
      puts lintian.grep(/^E:/).join("\n")
    else
      puts "Package written to: #{filename}"
    end
  end
  
end
