# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

$install = <<SCRIPT
cd ~/
set -ex
apt-get update -qq
apt-get install -q -y build-essential curl libcurl4-openssl-dev nodejs git
debconf-set-selections <<< 'mysql-server mysql-server/root_password password vagrant'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password vagrant'
apt-get install -q -y mysql-server libmysqlclient-dev
echo insecure >> ~/.curlrc
su vagrant -c '/usr/bin/curl -sSL --insecure https://get.rvm.io | bash -s stable'
/bin/bash -l -c "/home/vagrant/.rvm/bin/rvm requirements"
su vagrant -c '/bin/bash -l -c "rvm install 2.1.1"'
SCRIPT

$setup = <<SCRIPT
mysql -u root -pvagrant -e "create database onebody_dev; grant all on onebody_dev.* to onebody@localhost identified by 'onebody';"
mysql -u root -pvagrant -e "create database onebody_test; grant all on onebody_test.* to onebody@localhost identified by 'onebody';"
SCRIPT

$bundle = <<SCRIPT
set -ex
cd /vagrant
su vagrant -c '/bin/bash -l -c "gem install bundler --no-ri --no-rdoc"'
su vagrant -c 'cp config/database.yml{.example,}'
su vagrant -c '/bin/bash -l -c "bundle install"'
su vagrant -l -c 'cd /vagrant; sed -e"s/SOMETHING_RANDOM_HERE/$(rake -s secret)/g" config/secrets.yml.example > config/secrets.yml'
su vagrant -c '/bin/bash -l -c "/home/vagrant/.rvm/gems/ruby-2.1.1@onebody/bin/rake db:migrate"'
SCRIPT

$run = <<SCRIPT
cd /vagrant
su vagrant -c '/bin/bash -l -c "bundle exec rails server -d -p 3000"'
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "phusion/ubuntu-14.04-amd64"
  config.vm.network "forwarded_port", guest: 3000, host: 8080
  config.ssh.forward_agent = true

  config.vm.provision :shell, :inline => $install
  config.vm.provision :shell, :inline => $setup
  config.vm.provision :shell, :inline => $bundle
  config.vm.provision :shell, :inline => $run, run: "always"
end
