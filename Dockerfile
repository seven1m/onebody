FROM ubuntu:14.04

# install build tools
RUN apt-get update && apt-get install -y -q wget git supervisor vim build-essential curl libreadline-dev libcurl4-openssl-dev nodejs git libmysqlclient-dev imagemagick mysql-server nginx && apt-get clean

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
COPY .ruby-version /var/www/onebody/.ruby-version
COPY Gemfile /var/www/onebody/Gemfile
COPY config/email.yml /var/www/onebody/config/email.yml
COPY config/database.yml /var/www/onebody/config/database.yml
COPY config/secrets.yml /var/www/onebody/config/secrets.yml

# install gems
USER onebody
WORKDIR /var/www/onebody
RUN bundle install

USER root
# allow onebody user to run special 'chown_data' script as root
# workaround for volumes readonly to non-root users
RUN echo "ALL ALL=NOPASSWD: /var/www/onebody/script/docker/chown_data" > /etc/sudoers.d/chown_data

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

RUN echo '; supervisor config file\n\
[supervisord]\n\
nodaemon=true\n\
\n\
[program:startup]\n\
priority=1\n\
command=/start\n\
stdout_logfile=/var/log/supervisor/%(program_name)s.log\n\
stderr_logfile=/var/log/supervisor/%(program_name)s.log\n\
autorestart=false\n\
startsecs=0\n\
\n\
[program:nginx]\n\
priority=10\n\
command=nginx -g "daemon off;"\n\
stdout_logfile=/var/log/supervisor/nginx.log\n\
stderr_logfile=/var/log/supervisor/nginx.log\n\
autorestart=true\n\
\n\
[include]\n\
files = /etc/supervisor/conf.d/*.conf'\
>> /etc/supervisor/supervisord.conf

# share port
EXPOSE 8080

# serve assets with rack
ENV SERVE_ASSETS true
RUN echo "#!/bin/bash\n\ncd /var/www/onebody\nbundle exec rails server -d\n" > /start && chmod +x /start
CMD ["/usr/bin/supervisord", "-n"]
