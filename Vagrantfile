# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

$setup = <<SCRIPT
cd ~/
set -ex

# install prerequisites
apt-get update -qq
apt-get install -q -y build-essential curl libcurl4-openssl-dev nodejs git
debconf-set-selections <<< 'mysql-server mysql-server/root_password password vagrant'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password vagrant'
apt-get install -q -y mysql-server libmysqlclient-dev

# setup db
mysql -u root -pvagrant -e "create database if not exists onebody_dev; grant all on onebody_dev.* to onebody@localhost identified by 'onebody';"
mysql -u root -pvagrant -e "create database if not exists onebody_test; grant all on onebody_test.* to onebody@localhost identified by 'onebody';"

# install rvm, ruby and gems, run migrations
user=$(cat <<USER
  set -ex
  if [[ ! -d \\$HOME/.rvm ]]; then
    curl -sSL --insecure https://get.rvm.io | bash -s stable
    \\$HOME/.rvm/bin/rvm requirements
  fi
  source \\$HOME/.rvm/scripts/rvm
  rvm use --install 2.1.1
  cd /vagrant
  gem install bundler --no-ri --no-rdoc
  if [[ ! -e config/database.yml ]]; then
    cp config/database.yml{.example,}
  fi
  bundle install
  if [[ ! -e config/secrets.yml ]]; then
    secret=\\$(/home/vagrant/.rvm/gems/ruby-2.1.1@onebody/bin/rake -s secret)
    sed -e"s/SOMETHING_RANDOM_HERE/\\$secret/g" config/secrets.yml.example > config/secrets.yml
  fi
  \\$HOME/.rvm/gems/ruby-2.1.1@onebody/bin/rake db:migrate
USER
)
su - vagrant -c "$user"
SCRIPT

$run = <<SCRIPT
su - vagrant -c "cd /vagrant && bundle exec rails server -d -p 3000"
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "phusion/ubuntu-14.04-amd64"
  config.vm.network "forwarded_port", guest: 3000, host: 8080
  config.ssh.forward_agent = true

  config.vm.provision :shell, inline: $setup
  config.vm.provision :shell, inline: $run, run: "always"
end
