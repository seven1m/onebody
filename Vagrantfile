# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

$setup = <<SCRIPT
cd ~/
set -ex

# install prerequisites
apt-get update -qq
debconf-set-selections <<< 'mysql-server mysql-server/root_password password vagrant'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password vagrant'
apt-get install -q -y build-essential curl libcurl4-openssl-dev git mysql-server libmysqlclient-dev libgmp3-dev libaprutil1-dev libapr1-dev imagemagick libreadline6-dev ruby-dev libssl-dev

# node 8.x
curl -sL https://deb.nodesource.com/setup_8.x | bash -
apt-get install -y nodejs
npm install -g yarn

# ruby gems
gem update --system
gem install bundler

# setup db
mysql -u root -pvagrant -e "grant all on onebody_dev.*  to onebody@localhost identified by 'onebody';"
mysql -u root -pvagrant -e "grant all on onebody_test.* to onebody@localhost identified by 'onebody';"

cd /vagrant
bundle install

service=$(cat <<SERVICE
[Unit]
Description=Thin HTTP Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/vagrant
ExecStart=/usr/local/bin/bundle exec thin start
Restart=always

[Install]
WantedBy=multi-user.target vagrant.mount
SERVICE
)

echo "$service" > /etc/systemd/system/thin.service
systemctl enable thin.service
systemctl start thin.service

user=$(cat <<USER
  set -ex

  # setup db config
  cd /vagrant
  if [[ ! -e config/database.yml ]]; then
    cp config/database.yml{.mysql-example,}
  fi

  # install javascript dependencies
  yarn

  # setup config and migrate db
  if [[ ! -e config/secrets.yml ]]; then
    secret=\\$(rake -s secret)
    sed -e"s/SOMETHING_RANDOM_HERE/\\$secret/g" config/secrets.yml.example > config/secrets.yml
  fi
  \\rake db:create
  \\rake db:migrate db:seed
USER
)
su - vagrant -c "$user"
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.network "forwarded_port", guest: 3000, host: 3000, auto_correct: true
  config.ssh.forward_agent = true

  config.vm.provision :shell, inline: $setup
  config.vm.provision :shell, run: :always,
    inline: 'for i in 1 2 3 4 5; do echo "Trying to start Thin server..." && systemctl restart thin && echo "Thin started on port 3000" && break || sleep 4; done'

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # apply local customizations
  custom_file = File.expand_path("../Vagrantfile.local", __FILE__)
  eval(File.read(custom_file)) if File.exists?(custom_file)
end
