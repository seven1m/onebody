FROM ubuntu:14.04

# install build tools
RUN apt-get update
RUN apt-get install -y -q wget vim build-essential curl libreadline-dev libcurl4-openssl-dev nodejs git libmysqlclient-dev imagemagick mysql-client
RUN apt-get clean

# install Ruby
WORKDIR /tmp
RUN wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz && tar xzvf ruby-2.1.2.tar.gz
WORKDIR /tmp/ruby-2.1.2
RUN ./configure --disable-install-doc && make install
RUN rm -rf /tmp/ruby-2.1.2*
RUN gem install bundler --no-rdoc --no-ri

# set up user
RUN adduser --gecos "" --disabled-password --home=/home/onebody onebody

# from here on, be onebody
USER onebody
ENV HOME /home/onebody
ENV GEM_HOME /home/onebody/.gems

# set default rails env
ENV RAILS_ENV production

# add Gemfile first, then bundle install; this will make our builds cleaner
ADD .ruby-version /var/www/onebody/.ruby-version
ADD Gemfile /var/www/onebody/Gemfile
ADD Gemfile.lock /var/www/onebody/Gemfile.lock

# install gems
WORKDIR /var/www/onebody
RUN bundle install
RUN gem install thin --no-rdoc --no-ri

# add rest of source
USER root
ADD . /var/www/onebody
RUN chown -R onebody /var/www/onebody

# copy scripts
COPY script/docker/server /server
COPY script/docker/console /console

# fix for permissions bug
# https://github.com/dotcloud/docker/issues/2969
# https://github.com/kalamuna/kaladata-docker/commit/9e843ed361528011635d0290b095bb0050fcf32e
RUN mkdir -p /data
RUN touch /data/.perm-fix
RUN chown -R onebody /data

# set up shared directories
USER onebody
VOLUME /data

# compile assets
WORKDIR /var/www/onebody
RUN bundle exec rake assets:precompile

# share port
EXPOSE 3000

# serve assets with rack
ENV SERVE_ASSETS true

CMD /server
