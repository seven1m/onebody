# Install/Upgrade

Installation has been tested on Ubuntu Linux 10.04.1 LTS (Lucid Lynx) and 10.10 (Maverick Meerkat). If you are using a different Linux distro or Mac OS X, you will need to adjust some of the commands below to match your environment.

Supplemental install notes are available for CentOS 5.5 in the `doc` folder.


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

### 2. Install Git, RVM, and more <span style="color:red;">[Server]</span>

    sudo apt-get install git-core curl build-essential zlib1g-dev libssl-dev libreadline5-dev openssh-server imagemagick rsync postfix courier-pop
    bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-latest )
    echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"' >> ~/.bashrc

Log out and back in for the changes to take effect. Typing `type rvm | head -n1` should display
"rvm is a function".

**See http://rvm.beginrescueend.com/rvm/install/ and make sure your .bashrc doesn't exit near the top.**

_Be sure to configure your firewall to allow access to your SSH server from your workstation._

### 3. Copy Your SSH Key <span style="color:green;">[Workstation]</span>

This is optional, but recommend to avoid typing your deploy password a lot.

Replace `SERVER` with the fully qualified hostname of your remote server.

    [[ -f ~/.ssh/id_rsa.pub ]] || ssh-keygen
    ssh deploy@SERVER "mkdir -p ~/.ssh; echo `cat ~/.ssh/id_rsa.pub` >> ~/.ssh/authorized_keys"

_You may need to `chmod 600 ~/.ssh/authorized_keys` as well._

_This will be different on Windows of course._

### 4. Install Server Software <span style="color:red;">[Server]</span>

    sudo apt-get install mysql-server apache2 apache2-prefork-dev libapr1-dev libaprutil1-dev libcurl4-openssl-dev libxml2-dev libxslt1-dev
    rvm install ree
    rvm use ree@onebody --create --default
    gem install passenger
    rvmsudo passenger-install-apache2-module
    rvmsudo passenger-install-apache2-module --snippet | sudo tee /etc/apache2/conf.d/passenger

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

**On passwords:**

* First, you'll be asked for your 'deploy' password since this issues a `sudo` command on the server.
* When asked for the "MySQL ROOT password" -- this is the password you set up for the MySQL root user when you installed MySQL. If you left it blank, then just hit enter when prompted.
* When asked for the "Password to use for the onebody MySQL user" -- this can be anything you want.

If everything works as planned, you can move on to the biggie:

    cap deploy:migrations

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

**Backup your MySQL database and your `db` directory first!**

### Upgrade Notes

Check the Google Group for details on specific releases. I try to send a message whenever I run into notable issues.

There are a few different ways to upgrade your existing OneBody install, depending on how you installed the software originally...

### I originally installed via Capistrano.

Try this on your <span style="color:green;">Workstation</span>:

    git fetch origin --tags && git checkout stable
    # update your config/deploy.rb to add the RVM setup at the bottom
    cap deploy:migrations

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
4. Run `cap deploy:migrations`.
5. Point your existing virtual host (`/etc/apache/sites-available/something`) to `/var/www/apps/onebody/current/public`
6. Start Apache: `sudo /etc/init.d/apache2 start`
