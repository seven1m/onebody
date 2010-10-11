namespace :prepare do

  def confirm
    puts
    puts "**************************************************************************"
    puts " WARNING: This will install a lot of software on your server using the    "
    puts " native packagement management system. If you want more control over      "
    puts " what is being installed and how, STOP NOW.                               "
    puts
    puts " You can find detailed install instructions in the INSTALL file.          "
    puts "**************************************************************************"
    puts
    puts "Before continuing, please make sure your server has ssh installed and it  "
    puts "has a 'deploy' user with the ability to issue 'sudo' commands.            "
    puts
    confirm = Capistrano::CLI.ui.ask('Do you want to continue? ') { |q| q.in = %w(y Y n N) }
    exit(1) if confirm.downcase == 'n'
  end

  def validate_os(regex)
    unless `lsb_release -d` =~ regex
      puts "Your server operating system is not supported by this command."
      exit(1)
    end
  end

  namespace :ubuntu do

    desc 'Installs all prerequisites and gets a bare Ubuntu server ready for OneBody.'
    task :default do
      puts "This will prepare Ubuntu 10.04 or 10.10 so that OneBody can be deployed."
      validate_os(/Ubuntu 10\.(04|10)/)
      confirm
      prereqs
      rvm
      ree
      mysql
      apache
      passenger
      postfix
    end

    task :prereqs do
      sudo "DEBIAN_FRONTEND=noninteractive apt-get update"
      sudo "DEBIAN_FRONTEND=noninteractive apt-get install git-core curl build-essential zlib1g-dev libssl-dev libreadline5-dev imagemagick rsync -q -y"
    end

    task :rvm do
      run "cd && " + \
          "wget http://rvm.beginrescueend.com/releases/rvm-install-latest && " + \
          "chmod +x rvm-install-latest && " + \
          "./rvm-install-latest; " + \
          "echo '[[ -s \"$HOME/.rvm/scripts/rvm\" ]] && . \"$HOME/.rvm/scripts/rvm\"' >> ~/.bashrc"
    end

    task :ree do
      run "~/.rvm/bin/rvm install ree && ~/.rvm/bin/rvm use ree@onebody --create --default"
    end

    task :mysql do
      sudo "DEBIAN_FRONTEND=noninteractive apt-get install mysql-server -q -y"
    end

    task :apache do
      sudo "DEBIAN_FRONTEND=noninteractive apt-get install apache2 -q -y"
    end

    task :passenger do
      sudo "DEBIAN_FRONTEND=noninteractive apt-get install apache2-prefork-dev libapr1-dev libaprutil1-dev libcurl4-openssl-dev libxml2-dev libxslt1-dev -q -y"
      run  "gem install passenger --pre && " + \
           "rvmsudo passenger-install-apache2-module -a && " + \
           "rvmsudo passenger-install-apache2-module --snippet | sudo tee /etc/apache2/conf.d/passenger",
           :shell => "~/.rvm/bin/rvm-shell"
      sudo "sed -i '/^P\\|^L/!d' /etc/apache2/conf.d/passenger" # remove extraneous ansi escape sequence from snippet output
    end

    task :postfix do
      sudo "DEBIAN_FRONTEND=noninteractive apt-get install postfix courier-pop -q -y"
    end

  end

end
