namespace :onebody do

  # prereqs:
  # sudo aptitude install ruby irb1.8 rake rdoc1.8 ruby1.8-dev mysql-server postfix courier-pop libmysql-ruby1.8 build-essential imagemagick apache2 apache2-threaded-dev apache2-mpm-worker apache2-threaded-dev libxml2-dev libxslt1-dev libcurl4-gnutls-dev libhttp-access2-ruby1.8 makepasswd rsync cron wget

  desc 'Build a Debian package for installation.'
  task :deb do
  
    def cp_erb(name, destination, chmod=nil)
      content = ERB.new(File.read(Rails.root.join("lib/tasks/deb/#{name}"))).result(binding)
      File.open(Rails.root.join("pkg/#{destination}"), 'w') { |f| f.write(content) }
      if chmod
        FileUtils.chmod(chmod, Rails.root.join("pkg/#{destination}"))
      end
    end
  
    VERSION = File.read(Rails.root.join('VERSION')).strip
    
    DEB_VERSION = "#{VERSION}-1"
    
    FileUtils.rm_rf(Rails.root.join('pkg'))
    FileUtils.mkdir_p(Rails.root.join('pkg/usr/lib/onebody'))
    FileUtils.mkdir_p(Rails.root.join('pkg/usr/share/doc/onebody'))
    FileUtils.mkdir_p(Rails.root.join('pkg/usr/bin'))
    FileUtils.mkdir_p(Rails.root.join('pkg/DEBIAN'))

    cp_erb('copyright.erb',     'usr/share/doc/onebody/copyright')
    cp_erb('control.erb',       'DEBIAN/control'             )
    cp_erb('postinst.erb',      'DEBIAN/postinst',       0755)
    cp_erb('prerm.erb',         'DEBIAN/prerm',          0755)
    cp_erb('setup-onebody.erb', 'usr/bin/setup-onebody', 0755)
    
    # changelog
    VERSIONS = []
    File.read(Rails.root.join('CHANGELOG.markdown')).split(/\n/).each do |part|
      if part =~ /^([\d\.]+) \/ ([a-z]+ \d+, \d{4})/i
        date = Date.parse($2) rescue Date.today
        VERSIONS << [$1, date, []]
      elsif part =~ /^\* (.+)/ and VERSIONS.any?
        VERSIONS.last.last << $1
      elsif part =~ /^\*\*Upgrade Note:\*\* (.+)/ and VERSIONS.any?
        VERSIONS.last.last << 'Upgrade Note: ' + $1
      end
    end
    cp_erb('changelog.erb',        'usr/share/doc/onebody/changelog')
    cp_erb('changelog.erb',        'DEBIAN/changelog')
    cp_erb('changelog.Debian.erb', 'usr/share/doc/onebody/changelog.Debian')
    `gzip --best #{Rails.root}/pkg/usr/share/doc/onebody/changelog`
    `gzip --best #{Rails.root}/pkg/usr/share/doc/onebody/changelog.Debian`

    # clone repo, unpack rails + gems, clean up
    `git checkout-index -a -f --prefix=/tmp/onebody/ && mv /tmp/onebody/* #{Rails.root}/pkg/usr/lib/onebody/`
    `rm -rf #{Rails.root}/pkg/usr/lib/onebody/db/photos`
    `rm -rf #{Rails.root}/pkg/usr/lib/onebody/db/attachments`
    `cd #{Rails.root}/pkg/usr/lib/onebody && rake gems:unpack:dependencies`
    `cd #{Rails.root}/pkg/usr/lib/onebody && rake rails:freeze:gems`
    `find #{Rails.root}/pkg -name .gitignore | xargs rm`
    `rm #{Rails.root}/pkg/usr/lib/onebody/LICENSE`
    
    # tweak file locations to conform to Debian standards
    cp_erb('links.erb', 'usr/lib/onebody/config/initializers/links.rb')
    `sed -i -r -e 's/(config\\.action_controller\\.cache_store = :file_store, ).+$/\\1"\\/var\\/cache\\/onebody"/' #{Rails.root}/pkg/usr/lib/onebody/config/environment.rb`
    `sed -i -r -e 's/(config\\.log_path = ).+$/\\1"\\/var\\/log\\/onebody\\/\\\#{Rails.env}.log"/' #{Rails.root}/pkg/usr/lib/onebody/config/environment.rb`
    `sed -i -r -e 's/(config\\.database_configuration_file = ).+$/\\1"\\/etc\\/onebody\\/database.yml"/' #{Rails.root}/pkg/usr/lib/onebody/config/environment.rb`
    `sed -i -r -e 's/config\\/email\\.yml/\\/etc\\/onebody\\/email.yml"/' #{Rails.root}/pkg/usr/lib/onebody/config/schedule.rb`
    `sed -i -r -e "s/File\\.dirname\\(__FILE__\\) \\+ '\\/\\.\\.\\/email\\.yml'/'\\/etc\\/onebody\\/email.yml'/" #{Rails.root}/pkg/usr/lib/onebody/config/initializers/email.rb`

    # build deb
    filename = "onebody_#{DEB_VERSION}_all.deb"
    puts `fakeroot dpkg-deb --build pkg && mv pkg.deb #{Rails.root}/#{filename}`
    
    # look for errors
    lintian = `lintian #{filename}`
    puts "#{lintian.scan(/^W:/).length} warnings. Run `lintian #{filename}` to see them all."
    if lintian =~ /^E:/
      puts 'There were errors:'
      puts lintian.grep(/^E:/).join("\n")
    end
    puts "Package written to: #{filename}"
  end
  
end
