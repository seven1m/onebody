#!/bin/bash

set -e

sleep 10

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y curl
curl https://apt.church.io/gpg.key | sudo apt-key add -

echo "deb [arch=amd64] http://apt.church.io/ubuntu/nightly trusty main" | sudo tee /etc/apt/sources.list.d/onebody.list

sudo apt-get update
sudo apt-get install -y onebody nginx

mysql -uroot -e "grant all on onebody.* to onebody@localhost identified by 'onebody';"
sudo onebody run rake db:setup

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

sudo onebody run whenever -w

sudo apt-get clean
