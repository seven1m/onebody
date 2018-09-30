# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

$ruby_version = File.read(File.expand_path("../.ruby-version", __FILE__)).strip

$vhost = <<VHOST
<VirtualHost *:80>
  PassengerRuby /home/vagrant/.rvm/wrappers/ruby-#{$ruby_version}/ruby
  DocumentRoot /vagrant/public
  RailsEnv development
  <Directory /vagrant/public>
    AllowOverride all
    Options -MultiViews
    Require all granted
  </Directory>
</VirtualHost>
VHOST

$setup = <<SCRIPT
cd ~/
set -ex

# install prerequisites
apt-get update -qq
debconf-set-selections <<< 'mysql-server mysql-server/root_password password vagrant'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password vagrant'
apt-get install -q -y build-essential curl libcurl4-openssl-dev git mysql-server libmysqlclient-dev libgmp3-dev libaprutil1-dev libapr1-dev apache2 apache2-threaded-dev imagemagick

# node 8.x
curl -sL https://deb.nodesource.com/setup_8.x | bash -
apt-get install -y nodejs
npm install -g yarn

# setup db
mysql -u root -pvagrant -e "grant all on onebody_dev.*  to onebody@localhost identified by 'onebody';"
mysql -u root -pvagrant -e "grant all on onebody_test.* to onebody@localhost identified by 'onebody';"

user=$(cat <<USER
  set -ex

  # install rvm
  if [[ ! -d \\$HOME/.rvm ]]; then
    curl -sSL https://rvm.io/mpapis.asc | gpg --import
    curl -sSL --insecure https://get.rvm.io | bash -s stable
    \\$HOME/.rvm/bin/rvm requirements
  fi
  source \\$HOME/.rvm/scripts/rvm
  rvm use --install #{$ruby_version}

  # bundle gems
  cd /vagrant
  gem install bundler -v 1.9.4 --no-ri --no-rdoc
  if [[ ! -e config/database.yml ]]; then
    cp config/database.yml{.mysql-example,}
  fi
  bundle install

  # install javascript dependencies
  yarn

  # setup config and migrate db
  if [[ ! -e config/secrets.yml ]]; then
    secret=\\$(rake -s secret)
    sed -e"s/SOMETHING_RANDOM_HERE/\\$secret/g" config/secrets.yml.example > config/secrets.yml
  fi
  \\rake db:create
  \\rake db:migrate db:seed

  # install apache and passenger
  if [[ ! -e /etc/apache2/conf-available/passenger.conf ]]; then
    rvm use #{$ruby_version}@global
    # passenger 4.0.x doesn't like our git-sourced gems; use the previous version for now
    gem install passenger
    rvmsudo passenger-install-apache2-module -a
    rvmsudo passenger-install-apache2-module --snippet | sudo tee /etc/apache2/conf-available/passenger.conf
  fi
USER
)
su - vagrant -c "$user"

a2enconf passenger
a2enmod rewrite

if [[ ! -e /etc/apache2/sites-available/onebody.conf ]]; then
  echo -e "#{$vhost}" > /etc/apache2/sites-available/onebody.conf
  a2dissite 000-default
  a2ensite onebody
else
  echo -e "#{$vhost}" > /tmp/onebody.conf
  if diff /tmp/onebody.conf /etc/apache2/sites-available/onebody.conf > /dev/null
  then
    # the files are the same, do nothing
    echo "onebody.conf does not need to be updated"
  else
    # the files are different, update
    echo -e "#{$vhost}" > /etc/apache2/sites-available/onebody.conf
  fi
fi
service apache2 reload
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "phusion/ubuntu-14.04-amd64"
  config.vm.network "forwarded_port", guest: 80, host: 8080, auto_correct: true
  config.ssh.forward_agent = true

  config.vm.provision :shell, inline: $setup

  # apply local customizations
  custom_file = File.expand_path("../Vagrantfile.local", __FILE__)
  eval(File.read(custom_file)) if File.exists?(custom_file)

  # ...for example, you can give your box more ram by adding this to your Vagrantfile.local:
  #config.vm.provider :virtualbox do |vb|
  #  vb.customize ["modifyvm", :id, "--memory", "2048"]
  #end
end
