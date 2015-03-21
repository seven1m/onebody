FROM ubuntu:14.04

# install build tools
RUN apt-get update
RUN apt-get install -y -q wget vim build-essential curl libreadline-dev libcurl4-openssl-dev nodejs git libmysqlclient-dev imagemagick mysql-client
RUN apt-get clean

# install Ruby
RUN apt-get install -y software-properties-common
RUN apt-add-repository -y ppa:brightbox/ruby-ng
RUN apt-get update
RUN apt-get install -y ruby2.1 ruby2.1-dev
RUN gem install bundler --no-rdoc --no-ri

# install Passenger
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
RUN sudo apt-get install -y apt-transport-https ca-certificates
RUN echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main" > /etc/apt/sources.list.d/passenger.list
RUN chmod 600 /etc/apt/sources.list.d/passenger.list
RUN apt-get update
RUN apt-get install -y passenger

# set up user
RUN adduser --gecos "" --disabled-password --home=/home/onebody onebody
USER onebody
ENV HOME /home/onebody
ENV GEM_HOME /home/onebody/.gems

# set default rails env
ENV RAILS_ENV development

# copy the Gemfile so we can do bundle install
USER root
ADD config/database.yml /var/www/onebody/config/database.yml
ADD Gemfile /var/www/onebody/Gemfile
RUN chown -R onebody /var/www/onebody
USER onebody
WORKDIR /var/www/onebody
RUN bundle install

# share port
EXPOSE 3000

# serve assets with rack
ENV SERVE_ASSETS true

CMD passenger start --max-pool-size 5
