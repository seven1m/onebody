#!/bin/bash

set -e

sleep 10
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y -q curl
curl https://apt.church.io/gpg.key | sudo apt-key add -
echo "deb [arch=amd64] http://apt.church.io/ubuntu/stable xenial main" | sudo tee /etc/apt/sources.list.d/onebody.list
sudo apt-get update
sudo -E apt-get install -y -q onebody nginx
sudo onebody scale web=2

if [[ `grep RAILS_ENV .bashrc` == "" ]]; then
  echo "export RAILS_ENV=production" | sudo tee -a $HOME/.bashrc
fi

sudo mysql -uroot -e "grant all on onebody.* to onebody@localhost identified by 'onebody';"
sudo onebody run rake db:setup

sudo apt-get clean

sudo cp /opt/onebody/build/deb/vhost/nginx.conf /etc/nginx/sites-available/onebody
sudo sed 's/\( \+\)\(server 127.0.0.1:3000;\)/\1\2\n\1server 127.0.0.1:3001;/' /etc/nginx/sites-available/onebody
sudo ln -s /etc/nginx/sites-{available,enabled}/onebody
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -s reload
