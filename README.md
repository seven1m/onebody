# OneBody

OneBody is open-source, web-based social networking and online directory software for churches. OneBody is built on Ruby on Rails 2.3 and MySQL.

Screenshots and feature information can be found at the [commercial website](http://beonebody.com).


## Install Notes

If I could make you click an "I accept" button before downloading, I would. **Please be aware of the following:**

1. Installation of OneBody will likely take about an hour **if nothing goes wrong.**
2. I **strongly** recommend you get a dedicated server or a Virtual Private Server (VPS) running Ubuntu Linux.
3. If you instead choose to install on shared hosting (BlueHost, DreamHost, etc.), expect the process to take at least three hours or more, and be prepared to do **a lot of troubleshooting**.
4. **Installation on Windows is not supported. Don't ask.**
5. When following the steps below, watch at each point for errors. There's no use in continuing with the next step if you see an error (warnings are usually ok though).
6. Please do not bother the commercial support email address or the mailing list if you have not done some basic troubleshooting steps and read all relevant log files **first**.

Installation has been tested on Ubuntu Linux 10.04.1 LTS (Lucid Lynx) and 10.10 (Maverick Meerkat). If you are using a different Linux distro or Mac OS X, you will need to adjust some of the commands below to match your environment.


## Install Steps

We'll assume you have two computers; we'll call them the "Server" and the "Workstation." Perform each of the steps below, in order, paying close attention to where the commands should be run (<span style="color:red;">Server</span> and/or <span style="color:green;">Workstation</span>).

Do **not** run as the root user directly (use `sudo`).

### 0. Ruby on Your <span style="color:green;">[Workstation]</span>

You'll need Ruby 1.8.7 on your Workstation (other versions may work, but are untested).

For **Ubuntu** workstations, this should work (though RVM would be better here):

    sudo apt-get install ruby1.8 rubygems1.8

For **Windows** workstations, grab the 1.8.7 RubyInstaller from [here](http://ruby-lang.org/en/downloads/).

### 1. Create the Deploy User <span style="color:red;">[Server]</span>

    sudo adduser deploy
    sudo adduser deploy sudo
    exit

**Log back in as the _deploy_ user for all remaining Server instructions.**

### 2. Install Git, RVM, and SSH <span style="color:red;">[Server]</span>

    sudo apt-get install git-core curl build-essential zlib1g-dev libssl-dev libreadline5-dev openssh-server
    bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-latest )
    echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"' >> ~/.bashrc

Log out and back in for the changes to take effect. Typing `type rvm | head -n1` should display
"rvm is a function".

See http://rvm.beginrescueend.com/rvm/install/ for more detailed instructions.

_Be sure to configure your firewall to allow access to your SSH server from your workstation._

### 3. Copy Your SSH Key <span style="color:green;">[Workstation]</span>

Replace `SERVER` with the fully qualified hostname of your remote server.

    [[ -f ~/.ssh/id_rsa.pub ]] || ssh-keygen
    ssh deploy@SERVER "mkdir -p ~/.ssh; echo `cat ~/.ssh/id_rsa.pub` >> ~/.ssh/authorized_keys"

### 4. Install Server Software <span style="color:red;">[Server]</span>

    sudo apt-get install mysql-server apache2 apache2-prefork-dev libapr1-dev libaprutil1-dev libcurl4-openssl-dev libxml2-dev libxslt1-dev postfix courier-pop imagemagick rsync
    rvm install ree
    rvm ree
    rvm gemset create onebody
    rvm ree@onebody --default
    gem install passenger
    rvmsudo passenger-install-apache2-module
    rvmsudo passenger-install-apache2-module --snippet | sudo tee /etc/apache2/conf.d/passenger

_There is a bug in Passenger's --snippet command that causes an extra bit of text to be appended to the config file. You'll need to edit `/etc/apache2/conf.d/passenger` and remove the very last line._

See http://modrails.com/documentation/Users%20guide%20Apache.html for help with Passenger and http://rvm.beginrescueend.com/integration/passenger/ for more help setting up Passenger with RVM.

### 5. Download OneBody and Configure Capistrano <span style="color:green;">[Workstation]</span>

    git clone git://github.com/seven1m/onebody.git
    cd onebody

_If you don't have Git installed on your Workstation, you can download the tarball [here](http://github.com/seven1m/onebody/zipball/stable)._

    gem install capistrano
    cp config/deploy.rb.example config/deploy.rb

Edit the `config/deploy.rb` file and set `:host` to the fully qualified hostname or ip address of your remote server.

Now, we're ready to setup OneBody on the remote server using Capistrano. But don't switch to the Server just yet -- keep your fingers on your <span style="color:green;">Workstation</span> for this one:

    cap deploy:setup

If everything works as planned, you can move on to the biggie:

    cap deploy:install

See the [CapRecipes](http://github.com/seven1m/onebody/wiki/CapRecipes) page on the wiki for more information about the various cap commands.

### 6. Setup Virtual Host <span style="color:red;">[Server]</span>

Now create a file in `/etc/apache2/sites-available/onebody` and add the following to it:

    <VirtualHost *:80>
      ServerName example.com
      ServerAlias www.example.com
      DocumentRoot /var/www/apps/onebody/current/public
    </VirtualHost>

Save and enable:

    sudo a2ensite onebody
    sudo /etc/init.d/apache2 restart

If you don't have any other virtual hosts on your server, you can instead open up the `/etc/apache2/sites-available/default` file and change `DocumentRoot` to point to `/var/www/apps/onebody/current/public`. Then just restart Apache.

Now, visit your site with a web browser, and you should see a basic front page that reads: "There are no users in the system." That is expected.

### 7. Create the First User <span style="color:red;">[Server]</span>

    cd /var/www/apps/onebody/current
    rake onebody:new_user

Follow the instructions on the screen to create the first admin user. Now go back to your web browser, refresh the page, and log in with the newly-created admin account.

### 8. Setup Email <span style="color:red;">[Server]</span>

At this point, you should have a working install of OneBody, with the exception of incoming and outgoing email.

Please visit the [PostfixEmailSetup](http://github.com/seven1m/onebody/wiki/PostfixEmailSetup) page on the wiki for step-by-step instructions.

_Don't forget to point a DNS MX record at your server's IP address for incoming mail to work._


## Upgrade Steps

There are a few different ways to upgrade your existing OneBody install, depending on how you installed the software originally...

### I originally installed via Capistrano.

Try this on your <span style="color:green;">Workstation</span>:

    git fetch origin --tags && git checkout stable
    cap deploy:upgrade

If you get an error about missing `copy.rb`, see the related note in the "Troubleshooting" section below.

_Capistrano does the job of upgrading the OneBody source code on the server by cloning the Git repo, however you still should upgrade your local copy of OneBody since it's likely that the Capistrano recipes have been updated._

### I originally installed via Git, manually

It is strongly recommend you install using Capistrano (follow the directions in the "Install Steps" section and the "some other method" section immediately after this one), but if you would rather just upgrade your existing Git-based install, try this on your <span style="color:red;">Server</span>:

    cd /path/to/onebody
    git fetch origin --tags && git checkout stable
    rake gems:install
    rake db:migrate
    touch tmp/restart.txt

You will most likely need to upgrade certain things to make this work. See the "Troubleshooting" section below for help.

### I originally installed via some other method.

_The Debian package is no longer supported, since it was fairly error proned._

To upgrade, do the following on the <span style="color:red;">Server</span>:

1. Stop Apache: `sudo /etc/init.d/apache2 stop`
2. Perform a _new_ install by following the directions above, stopping before `cap deploy:setup`.
3. Run `cap deploy:setup SKIP_DB_SETUP=true`.
3. Edit `/var/www/apps/onebody/config/database.yml` and point it to your existing database name.
4. Run `cap deploy:install`.
5. Point your existing virtual host (`/etc/apache/sites-available/something`) to `/var/www/apps/onebody/current/public`
6. Start Apache: `sudo /etc/init.d/apache2 start`


## Troubleshooting

If you have trouble installing or upgrading, here are some steps to help before you yell on the mailing list "IT'S BROKE!"

1. Take a deep breath. The problem is almost certainly indicated on the screen or in a log somewhere.
2. _Read_ the error message. If you all you see is an "Oops" page, then check the logs (most recent errors at the bottom):
   * `/var/www/apps/onebody/shared/log/production.log`
   * `/var/log/apache/error.log`
3. Make a change, restart Apache, and try again.

Here are some common problems and solutions:

<dl>
<dt>The Rails 2.3.x gem is missing.</dt>
<dd>Run `gem install rails -v 2.3.x` (replace x with the number reported in the error)</dd>
<dt>`copy.rb` is missing</dt>
<dd>`scp vendor/plugins/fast_remote_cache/lib/capistrano/recipes/deploy/strategy/utilities/copy.rb deploy@SERVER:/var/www/apps/onebody/shared/bin/`</dd>
</dl>


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
