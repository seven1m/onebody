= Installation on CentOS

This document supplements the main install instructions available in the README.md and INSTALL.md files in the root of this project.

This has been tested with CentOS 5.5.


== SELinux

Unfortunately, to get Passenger to work right, I had to disable SELinux completely. If someone can get RVM + Passenger + SELinux to coexist on CentOS, let me know.

    vim /etc/selinux/config
    # set SELINUX=disabled


== Deploy User

Adding the 'deploy' user on a CentOS system looks like this:

    adduser deploy
    passwd deploy
    visudo
    # add 'deploy' as sudoer by copying ROOT line


== Preparation

There is a `prepare:centos` Capistrano recipe that attempts to get everything in working order on your server.

The recipe installs Git from the latest source tree. If you already have Git, or prefer to install Git yourself by some other means, skip to the next section.

Otherwise, it's just:

    # on your local machine:
    gem install capistrano
    # edit config/deploy.rb to point to your server
    cap prepare:centos
    # follow http://rvm.beginrescueend.com/rvm/install/
    # to ensure .bashrc doesn't exit near the top
    cap deploy:setup
    cap deploy:migrations

    # on your server
    # edit /etc/httpd/conf/httpd.conf
    # and point DocumentRoot to "/var/www/apps/onebody/current/public"

    # in your web browser:
    # visit http://your-server-name-or-ip


== Skipping Pieces of the Prepare Recipe

Like I said above, the default prepare recipe installs Git from source. If you don't want that, you can install the pieces individually and skip the git piece:

    cap prepare:centos:prereqs prepare:centos:rvm prepare:centos:ree prepare:centos:mysql prepare:centos:apache prepare:centos:passenger prepare:centos:bundler
    cap deploy:setup
    cap deploy:migrations

You can do this for any of the individual pieces. They are:

* prepare:centos:prereqs
* prepare:centos:git
* prepare:centos:rvm
* prepare:centos:ree
* prepare:centos:mysql
* prepare:centos:apache
* prepare:centos:passenger
* prepare:centos:bundler


== Troubleshooting

If any of the pieces of the recipe fail, check out the error and see if you can fix it in the `lib/recipes/prepare.rb` file. Or by hand on the server.

Then pick up where the recipe left off (see above section).


== Firewall

CentOS has iptables enabled by default. Follow [this link](http://www.cyberciti.biz/faq/howto-rhel-linux-open-port-using-iptables/) for help in allowing port 80 traffic.
