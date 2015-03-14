#!/bin/bash

set -e

sleep 10
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo -E apt-get install -y -q wget build-essential libcurl4-openssl-dev libmysqlclient-dev nodejs git imagemagick mysql-server apache2 libapache2-mod-xsendfile

sudo apt-get install -y software-properties-common
sudo apt-add-repository -y ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install -y ruby2.1 ruby2.1-dev
sudo gem install bundler --no-rdoc --no-ri

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
sudo apt-get install -y apt-transport-https ca-certificates
echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main" | sudo tee /etc/apt/sources.list.d/passenger.list
sudo chmod 600 /etc/apt/sources.list.d/passenger.list
sudo apt-get update
sudo apt-get install -y libapache2-mod-passenger
sudo a2enmod passenger
sudo a2enmod xsendfile
sudo sed -i "s/DocumentRoot.*/DocumentRoot \/var\/www\/onebody\/public\n\nXSendFile On\nXSendFilePath \/var\/www\/onebody\/public\/system/" /etc/apache2/sites-available/000-default.conf
sudo service apache2 restart

if [[ `grep RAILS_ENV .bashrc` == "" ]]; then
  echo "export RAILS_ENV=production" | sudo tee -a $HOME/.bashrc
fi

cd /var/www
[[ ! -e onebody ]] && sudo git clone git://github.com/churchio/onebody.git
sudo chown -R $USER /var/www/onebody

cd /var/www/onebody
git checkout stable

# brightbox may have a slightly newer version than we're pinned to -- that's ok
sed -i '/ruby-version/d' Gemfile

bundle install --deployment

mysql -uroot -e "create database if not exists onebody default character set utf8 default collate utf8_general_ci; grant all on onebody.* to onebody@localhost identified by 'onebody';"
if [[ -e config/database.yml.mysql-example ]]; then
  cp config/database.yml{.mysql-example,}
else
  cp config/database.yml{.example,}
fi
RAILS_ENV=production bundle exec rake db:migrate db:seed

cp config/secrets.yml{.example,}
secret=`bundle exec rake secret`
sed -i "s/SOMETHING_RANDOM_HERE/$secret/" config/secrets.yml

export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get install -y -q postfix courier-pop
sudo sed -i "s/mydestination.*/mydestination = localhost, your-domain-goes-here.com/" /etc/postfix/main.cf
if [[ `grep Maildir /etc/postfix/main.cf` == "" ]]; then
  echo -e "home_mailbox = Maildir/\nsmtp_discard_ehlo_keywords=pipelining,discard\nmessage_size_limit = 25600000\nlocal_recipient_maps =\nluser_relay = onebodymail" | sudo tee -a /etc/postfix/main.cf
fi
sudo postfix reload

if [[ ! -e /home/onebodymail ]]; then
  cd /var/www/onebody
  sudo adduser --gecos "" --disabled-password --home=/home/onebodymail onebodymail
  email_password=`bundle exec rake secret | head -c 16`
  echo -e "$email_password\n$email_password" | sudo passwd onebodymail
  echo -e "production:\n  pop:\n    host: localhost\n    username: onebodymail\n    password: $email_password\n  smtp:\n    address: localhost\n    domain: example.com\n    enable_starttls_auto: false" > config/email.yml
fi

bundle exec whenever -w

RAILS_ENV=production bundle exec rake tmp:clear assets:precompile
touch tmp/restart.txt

sudo apt-get clean
