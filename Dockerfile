FROM ubuntu:14.04

# install build tools
RUN apt-get update && apt-get install -y -q wget git vim build-essential curl libreadline-dev libcurl4-openssl-dev nodejs git libmysqlclient-dev imagemagick mysql-server && apt-get clean

# install passenger + nginx
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7 && apt-get install -y -q apt-transport-https ca-certificates && echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' > /etc/apt/sources.list.d/passenger.list && apt-get update && apt-get install -y -q nginx nginx-extras passenger && sed -i 's/# passenger_/passenger_/g' /etc/nginx/nginx.conf

# install Ruby
RUN apt-get install -y software-properties-common && apt-add-repository -y ppa:brightbox/ruby-ng && apt-get update && apt-get install -y ruby2.1 ruby2.1-dev && gem install bundler --no-rdoc --no-ri

# set up user with default password of onebody
RUN useradd -m -G sudo -p $(openssl passwd -1 "onebody") onebody

USER onebody
ENV GEM_HOME /home/onebody/.gems

# set default rails env
ENV RAILS_ENV production

# Git clone onebody
USER root
WORKDIR /var/www
RUN git clone git://github.com/churchio/onebody.git onebody && chown -R onebody /var/www/onebody

# Set up the database
RUN service mysql start && mysql -uroot -e "grant all on onebody.* to 'onebody'@'localhost' identified by 'onebody';"

# install gems
USER onebody
WORKDIR /var/www/onebody
#RUN sed -i "s/gem 'will_paginate'/gem 'will_paginate'\\ngem 'passenger'/g" Gemfile && bundle install
RUN bundle install

# Set up the secrets
RUN SECRET=$(rake -s secret) && sed "s/SOMETHING_RANDOM_HERE/"$SECRET"/g" config/secrets.yml.example > config/secrets.yml

# Set up the database
RUN cp config/database.yml.mysql-example config/database.yml

# Run rake tasts
USER root
RUN service mysql start && bundle exec rake db:create db:schema:load db:seed db:migrate

# allow onebody user to run special 'chown_data' script as root
# workaround for volumes readonly to non-root users
RUN echo "ALL ALL=NOPASSWD: /var/www/onebody/script/docker/chown_data" > /etc/sudoers.d/chown_data

# copy scripts
RUN echo "#!/bin/bash\n\n/var/www/onebody/script/docker/server \$@"  > /server  && chmod +x /server
RUN echo "#!/bin/bash\n\n/var/www/onebody/script/docker/console \$@" > /console && chmod +x /console

# compile assets
USER onebody
WORKDIR /var/www/onebody
RUN bundle exec rake assets:precompile

USER root

#set up nginx with one body
RUN echo 'upstream onebody {\n\
      server 127.0.0.1:3000;\n\
    }\n\
    server {\n\
    listen 8080 default_server;\n\
    server_name onebody;\n\
\n\
    # Tell Nginx where your app\'s \'public\' directory is\n\
    root /var/www/onebody/public;\n\
\n\
        location @onebody {\n\
            proxy_set_header  X-Real-IP        $remote_addr;\n\
            proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;\n\
            proxy_set_header  Host             $http_host;\n\
            proxy_redirect    off;\n\
            proxy_pass        http://onebody;\n\
        }\n\
        location / {\n\
          try_files $uri/index.html $uri @onebody;\n\
        }\n\
        \n\
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|woff|woff2)$ {\n\
                expires max;\n\
                log_not_found off;\n\
        }\n\
}'\
>> /etc/nginx/sites-enabled/onebody.conf


# share port
EXPOSE 8080

# serve assets with rack
ENV SERVE_ASSETS true
RUN echo "#!/bin/bash\n\nservice mysql start\ncd /var/www/onebody\nbundle exec rails server -d\n nginx -g \"daemon off;\"" > /start && chmod +x /start
CMD ["/start"]
