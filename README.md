# Church.IO OneBody

[![Build Status](https://travis-ci.org/churchio/onebody.png)](https://travis-ci.org/churchio/onebody)

OneBody is open-source, web-based social networking, email list, online directory, and lightweight document management software for churches.

*It's like a cross between Facebook, Google Groups, and SharePoint, but it's completely free and open source and awesome.*

OneBody is built with Ruby on Rails and MySQL, and has been in production use at churches for over seven years!

You can see lots of [screenshots here](https://www.flickr.com/photos/timothymorgan/sets/72157644451251789).

[![screnshots](https://farm4.staticflickr.com/3907/14330229528_250bd697d7.jpg)](https://www.flickr.com/photos/timothymorgan/sets/72157644451251789)

## Production Installation

Operating System: Linux (Debian/Ubuntu recommended)

First, a word of warning (this is the part where we try to talk you out of installing our beautifully and wonderfully hand-crafted software): OneBody is not a PHP app that can be FTP'd to a cheap web host. You *will* need a dedicated Linux server (or Virtual Private Server) with 1 Gb of memory and *root shell access*. We're sorry, that's just the way it is.

If you don't feel comfortable logging into a web server from the console, typing lots of commands, reading the output, Googling error messages, and generally troubleshooting the whole process, then please don't try this. If you don't have a few hours to spare, then don't try to rush it, as it will only end in frustration—It would be better for you find a consultant on freelancer.com or oDesk and pay them to do it.

On the other hand, if you're a I.T/sysadmin/hacker with guts, then please proceed to our 18 easy steps!

1. Get a Linux server with Debian or Ubuntu on it. If you are using RedHat/CentOS or SuSE or something else "enterprise" worthy, you're kinda on your own.

2. Install all this software first: `[sudo] apt-get install -y vim build-essential curl libreadline-dev libcurl4-openssl-dev nodejs git mysql-server libmysqlclient-dev libaprutil1-dev libapr1-dev apache2 apache2-threaded-dev libapache2-mod-xsendfile imagemagick`

    That command is for Debian/Ubuntu; if you're using another Linux distro, you'll need to find and install the same packages (possibly different names) using your distro's package management tool.

3. Install Ruby 2.1.2 or higher. It's doubtful your Linux distro has such a new release, so you'll need to install from source. Then follow [the instructions here](https://www.ruby-lang.org/en/installation/#building-from-source) for compiling Ruby.

    Don't move on from this step until you can type `ruby --version` and see "ruby 2.1.2" in your console.

4. `cd /var/www`, then type `git clone git://github.com/churchio/onebody.git && cd onebody`. This will put the latest and greatest, bleeding edge OneBody code in the `/var/www/onebody` directory.

    Now, it's recommened you switch to a tagged release of OneBody, which you can do with the command `git checkout 3.0.0.beta1` (that is the latest version as of Tim remembering to update this readme, but may not be *the* latest, so check out a [list of releases here](https://github.com/churchio/onebody/releases)).

5. Make sure Apache will be able to write tmp files and logs and such: `mkdir -p tmp/pids log` and `chmod -R 777 tmp log`.

6. Now, create your database: `mysql -u root -e "create database onebody default character set utf8 default collate utf8_general_ci; grant all on onebody.* to onebody@localhost identified by 'onebody';"`

    If you get an error about access being denied, then you may need to use `mysql -u root -p -e "..."` and enter your root password.

    You'll notice we set the username and password to "onebody" and "onebody". That is ok, as long as you: 1) trust all the users logging into this Linux server (or you're the only one), and 2) do not grant access to users outside of localhost (notice the `onebody@localhost` part). If you cannot answer yes to both of those questions, then please change the password to something else (you'll just need to change it also in the `config/database.yml` file in the next step) and make sure `/var/www/onebody` is not accessible to those devious users you let on your server. :-)

7. `cp config/database.yml{.example,}`

    If you used something other than "onebody" for your MySQL password, then change it appropriately in this file using vim or nano or another text editor.

8. `bundle install`

    Do not continue if you get an error saying something could not be downloaded/compiled/installed. There may be other development packages that need to be installed here, like "libxml", so read the errors carefully, install the needed stuff, then come back and run this command again.

9. `cp config/secrets.yml{.example,} && vim config/secrets.yml` and add a random secret token to the "production" section.

    (You can use `rake secret` to generate a new random secret, or just make up something really long and random by smashing your head on the keyboard.)

10. `RAILS_ENV=production rake db:migrate`

    Watch the output! Don't move on if you see an error on the screen.

11. Read [this help document about installing Passenger](https://www.phusionpassenger.com/documentation/Users%20guide%20Apache.html#installation), then:

12. `[sudo] gem install passenger` then `[sudo] passenger-install-apache2-module`.

    Read the screens! If there are other dependencies you need, the Passenger install will tell you here. Don't move on until you see this process complete successfully.

13. Now write your Apache module config with a command like this: `passenger-install-apache2-module --snippet | [sudo] tee /etc/apache2/conf.d/passenger`

    The location of your apache conf/conf.d directory may be different than this. If so, adjust accordingly.

    If all else fails, run `passenger-install-apache2-module --snippet` and paste the output into your apache2.conf or httpd.conf file.

    Then `[sudo] service apache2 restart`. If the restart fails, then go back to step 11 and try again.

14. Now we basically have to assume you're on Ubuntu or Debian, because every Linux distro does this differently. The goal here is to edit the default vhost (or create a new vhost) and point the DocumentRoot to the `onebody/public` folder.

    For Debian, that looks something like this: `vim /etc/apache2/sites-available/default` and change the DocumentRoot to be `/var/www/apps/onebody/public`.

    Next you need to add these two lines to the config: `XSendFile On` and `XSendFilePath /var/www/onebody`. So, to recap, you need to have the following three lines in your Apache vhost:

        DocumentRoot /var/www/onebody/public
        XSendFile On
        XSendFilePath /var/www/onebody/public/system

15. Now enable the xsendfile Apache module: `[sudo] a2enmod xsendfile` and restart Apache: `[sudo] service apache2 restart`.

    Now, if you did all that right, you probably have OneBody running on your host. You will want to map a domain to your host with DNS, but to test it out, type `http://YOUR_IP_HERE` into a browser. If nothing comes up, you'll need to troubleshoot a few things (not in the scope of this readme), such as firewall (iptables), is that the right _public_ IP address, etc. God be with you!

    Oh, and a few more things:

16. Follow the steps in [PostfixEmailSetup](http://github.com/churchio/onebody/wiki/PostfixEmailSetup) on the wiki for help with setting up incoming and outgoing email. OneBody isn't half as good without this working...

17. `RAILS_ENV=production whenever -w` to write the user crontab.

    This is necessary for a whole lot of things (you can see what it wrote by typing `crontab -e`) such as incoming email, printed directory job, group membership updates, etc.

18. Get an SSL certificate and:

    1. Setup Apache to only serve OneBody on SSL port 443.
    2. Redirect non-SSL traffic to the secure site.

Whew! We know that was a lot. If you made it this far, and OneBody is running, then congratulations!

What's next? Complete the form on the initial Setup screen, then head over to the Settings page in the Admin dashboard, and start customizing!

## Production Deployment with Capistrano

If you're familiar with Capistrano deployments, you can probably make use of the existing `config/deploy.rb` along with your own `config/deploy/production.rb` that includes your server name and custom config.

If you've never heard of Capistrano and/or you don't love thinking about spending your precious time automating server stuff, then you should probably go back up to the previous section for the manual install instructions. :-)

## Development Setup using Vagrant

Operating System: Windows, Mac, or Linux

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads). It's free and it runs on Windows, Mac, and Linux.
2. Install [Vagrant](http://docs.vagrantup.com/v2/installation/index.html).
3. `git clone git://github.com/churchio/onebody.git && cd onebody`
4. `vagrant up`

Now visit the site running in development mode at localhost:8080

Whenever gems are updated or new migrations are needed, you can just run `vagrant provision`.

To restart the Rails server, type `touch tmp/restart.txt`. Or you can `vagrant reload` to restart the dev box.

For more help with Vagrant, check out the [Vagrant docs](http://docs.vagrantup.com/v2/).

## Development Setup the Manual Way

Operating System: Mac or Linux (See Vagrant above if you're on Windows)

1. Install Ruby 2.1.2 or higher (we recommend you use [RVM](https://rvm.io/)).
2. Install MySQL.
3. Install Git.
4. `git clone git://github.com/churchio/onebody.git && cd onebody`
5. `mysql -u root -e "create database onebody_dev default character set utf8 default collate utf8_general_ci; grant all on onebody_dev.* to onebody@localhost identified by 'onebody';"`
6. `cp config/database.yml{.example,}`
7. `bundle install`
8. `cp config/secrets.yml{.example,} && vim config/secrets.yml` and add a random secret token to both the "development" and "test" sections (you can use `rake secret` to generate a new random secret).
9. `rake db:migrate`
10. `rails server`

Now visit the site running in development mode at http://localhost:3000.

## Tests

To run tests:

```
mysql -u root -e "create database onebody_test default character set utf8 default collate utf8_general_ci; grant all on onebody_test.* to onebody@localhost identified by 'onebody';"
rspec
```

## Get Help

* IRC channel #church.io on Freenode (try the [web-based IRC client](https://webchat.freenode.net/?channels=#church.io))
* [Wiki](http://wiki.github.com/churchio/onebody) - There is some (possibly outdated) information here. We'll work to clean this up shortly after releasing 3.0.
* [Google Group](http://groups.google.com/group/churchio) - Community of people building open source church software. If you're stuck, ask nicely for some help and you will probably get it.


## Copyright

Copyright (c) [Tim Morgan](http://timmorgan.org)

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

This software is license under the GNU Affero General Public License, version 3. See LICENSE provided with this program for the entire text.

### Design

Design is a derivative of AdminLTE, copyright (c) almasaeed2010, available [here](https://github.com/almasaeed2010/AdminLTE), licensed under MIT license. See [LICENSE](https://github.com/almasaeed2010/AdminLTE/blob/master/LICENSE).
