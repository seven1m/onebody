# OneBody

OneBody is open-source, web-based social networking and online directory software for churches. OneBody is built on Ruby on Rails 2.3 and MySQL.

Screenshots and feature information can be found at the [commercial website](http://beonebody.com).


## Install on Ubuntu

OneBody is a complex app with a lot of moving parts. Installation can be lengthy, so we've tried to automate as much of the process as possible using [Capistrano](http://github.com/capistrano/capistrano).

If you're dedicated server or VPS is Ubuntu 10.04 or higher, try this:

    # 1. on your server:
    sudo adduser deploy
    sudo adduser deploy sudo
    # copy your SSH public key to avoid password prompts
    sudo apt-get install git-core curl build-essential zlib1g-dev libssl-dev libreadline5-dev imagemagick rsync
    # follow http://rvm.beginrescueend.com/rvm/install/ to install RVM
    rvm install ree
    rvm use ree@onebody --create --default

    # 2. on your local machine:
    gem install capistrano
    # edit config/deploy.rb to point to your server
    cap prepare:ubuntu:mysql
    cap prepare:ubuntu:apache
    cap prepare:ubuntu:passenger
    cap prepare:ubuntu:postfix
    cap prepare:ubuntu:bundler
    cap deploy:setup
    cap deploy:migrations

    # 3. on your server
    # edit /etc/apache2/sites-available/default
    # and point DocumentRoot to "/var/www/apps/onebody/current/public"
    sudo /etc/init.d/apache2 reload
    # you may also need to set smtpd_use_tls=no in your /etc/postfix/main.cf

    # 4. in your web browser:
    # visit http://your-server-name-or-ip

We also have full step-by-step instructions in our INSTALL.md file.

Please visit the [PostfixEmailSetup](http://github.com/seven1m/onebody/wiki/PostfixEmailSetup) page on the wiki for help with setting up incoming email.


## More Information

* [Wiki](http://wiki.github.com/seven1m/onebody) - A wonderful resource full of helpful information; Check here first.
* [Blog](http://blog.beonebody.com) - Some intermittent updates about new features.
* [Google Group](http://groups.google.com/group/onebodyapp) - Community of hackers working on OneBody and running their own OneBody servers. If you're stuck, ask nicely for some help and you will probably get it.
* [Twitter](http://twitter.com/onebody) - Status updates for beonebody.com and occasional feature notes.


## Copyright

Copyright (c) 2008-2010, [Tim Morgan](http://timmorgan.org)


## Disclaimer & License

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

This software is license under the GNU Affero General Public License, version 3. See LICENSE provided with this program for the entire text.
