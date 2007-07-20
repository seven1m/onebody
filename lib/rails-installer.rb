require 'rubygems'

require 'fileutils'
require 'yaml'
require 'digest/sha1'

require File.join(File.dirname(__FILE__), 'rails-installer/databases')
require File.join(File.dirname(__FILE__), 'rails-installer/web-servers')
require File.join(File.dirname(__FILE__), 'rails-installer/commands')

#
# = Rails Application Installer
# An installer for Rails applications.
#
# The Rails Application Installer is designed to make it easy for end-users to
# install open-source Rails apps with a minimum amount of effort.  When built 
# properly, all the user needs to do is run:
#
#    $ sudo gem install my_app
#    $ my_app install /some/path
#
# Users who need to install your .gem but don't have the right permissions can
# do this instead:
#
#    $ export GEM_PATH=~/gems
#    $ gem install -i ~gems my_app
#    $ ~gems/bin/my_app install /some/path
#
# == Adding the installer to your application
#
# (This example assumes that your program is called 'my_app'.  Change this to
# match your application's actual name)
# 
# First, create a small driver program and put it into bin/my_app. 
# Here's a minimal example:
#
#    #!/usr/bin/env ruby
#
#    require 'rubygems'
#    require 'rails-installer'
#
#    class AppInstaller < RailsInstaller
#      application_name 'my_app'
#      support_location 'our shiny website'
#      rails_version '1.1.6'
#    end
#
#    # Installer program
#    directory = ARGV[1]
#
#    app = AppInstaller.new(directory)
#    app.message_proc = Proc.new do |msg|
#      STDERR.puts " #{msg}"
#    end
#    app.execute_command(*ARGV)
#
# This is a simple example; you can extend the installer to add new commands and
# install steps.  See the examples/ directory for more complex examples.
#
# Second, you'll need some schema files in db/schema.*.sql.  The schema_generator
# plugin can generate these automatically from your migrations:
#
#    $ sudo gem install schema_generator
#    $ ./script/generate schemas
#    $ svn add db/schema.*.sql
#    $ svn add db/schema_version
#
# Third, build a .gem file.  Make sure that it depends on the rails-app-installer
# GEM.  Make sure that the generated schema files and the installer that you put in
# bin/ are included in your .gem, and the gem knows that bin/my_app is supposed to
# be executable.  Here's an example from Typo's .gemspec.  This may be more complex
# then you need.
#
#    $:.unshift '../lib'
#    require 'rubygems'
#    require 'rake'
#
#    spec = Gem::Specification.new do |s|
#      s.name = "typo"
#      s.version = "4.0.2"
#      s.summary = "Modern weblog engine."
#      s.has_rdoc = false
#  
#      s.files = Dir.glob('**/*', File::FNM_DOTMATCH).reject do |f| 
#         [ /\.$/, /config\/database.yml$/, /config\/database.yml-/, 
#         /database\.sqlite/,
#         /\.log$/, /^pkg/, /\.svn/, /^vendor\/rails/, 
#         /^public\/(files|xml|articles|pages|index.html)/, 
#         /^public\/(stylesheets|javascripts|images)\/theme/, /\~$/, 
#         /\/\._/, /\/#/ ].any? {|regex| f =~ regex }
#      end
#      s.require_path = '.'
#      s.author = "Tobias Luetke"
#      s.email = "tobi@leetsoft.com"
#      s.homepage = "http://www.typosphere.org"  
#      s.rubyforge_project = "typo"
#      s.platform = Gem::Platform::RUBY 
#      s.executables = ['typo']
#  
#      s.add_dependency("rails", "= 1.1.6")
#      s.add_dependency("rails-app-installer", ">= 0.1.2")
#    end
#
#    if $0==__FILE__
#      Gem::manage_gems
#      Gem::Builder.new(spec).build
#    end
#
# == Using your .gem
#
# You can test your new gem by running 'sudo gem install ./my_app-1.0.0.gem'.  Once you're
# happy with it, upload it to Rubyforge and it'll automatically be added to the master
# gem index.
#
# Users should be able to download and install it using the commands at the top of this
# document.
#
# === Non-standard install options
#
# By default, the installer uses SQLite3 and Mongrel when installing your app.
# The user can override this at install time with some flags.  Examples:
# 
#    # install using SQLite3 and Mongrel
#    $ my_app install /some/path
#
#    # install using MySQL and Mongrel
#    $ my_app install /some/path database=mysql db_user=my_app db_name=my_app db_host=localhost db_password=password
#
#    # install using PostgreSQL and Mongrel
#    $ my_app install /some/path database=postgresql db_user=my_app db_name=my_app db_host=localhost db_password=password
#
#    # install using SQLite3 and mongrel_cluster
#    $ my_app install /some/path web-server=mongrel_cluster threads=4
#
class RailsInstaller
  include FileUtils
  attr_accessor :install_directory, :source_directory, :config
  attr_accessor :message_proc
  
  class InstallFailed < StandardError; end

  @@rails_version = nil
  
  # The application name.  Set this in your derived class.
  def self.application_name(name)
    @@app_name = name
  end
  
  # The support location.  This is displayed to the user at the end of the 
  # install process.
  def self.support_location(location)
    @@support_location = location
  end
  
  # Which Rails version this app needs.  This version of Rails will be frozen
  # into vendor/rails/
  def self.rails_version(svn_tag)
    @@rails_version = svn_tag
  end
  
  # The application name, as set by +application_name+.
  def app_name
    @@app_name
  end

  def initialize(install_directory)
    # use an absolute path, not a relative path.
    if install_directory
      @install_directory = File.expand_path(install_directory)
    end
        
    @config = read_yml(config_file) rescue nil
    @config ||= Hash.new
  end
  
  # Display a status message
  def message(string)
    if message_proc
      message_proc.call(string)
    else
      STDERR.puts string
    end
  end

  # Install Application
  def install(version=nil)
    @source_directory = find_source_directory(@@app_name,version)

    # Merge default configuration settings
    @config = read_yml(backup_config_file).merge(config)
    
    install_sequence
    
    message ''
    message "#{@@app_name.capitalize} is now running on http://#{`hostname`.chomp}:#{config['port-number']}"
    message "Use '#{@@app_name} start #{install_directory}' to restart after boot."
    message "Look in installer/*.conf.example to see how to integrate with your web server."
  end
  
  # The default install sequence.  Override this if you need to add extra
  # steps to the installer.
  def install_sequence
    stop
    
    backup_database
    install_pre_hook
    pre_migrate_database
    copy_files
    freeze_rails
    create_default_config_files
    fix_permissions
    create_directories
    create_initial_database
    set_initial_port_number
    expand_template_files
    
    migrate
    install_post_hook
    save
    
    run_rails_tests
    
    start
  end
  
  # The easy way to add steps to the installation process.  +install_pre_hook+
  # runs right after the DB is backed up and right before the first migration
  # attempt.
  def install_pre_hook
  end
  
  # Another install hook; +install_post_hook+ runs after the final migration.
  def install_post_hook
  end
  
  # Start application in the background
  def start(foreground = false)
    server_class = RailsInstaller::WebServer.servers[config['web-server']]
    if not server_class
      message "** warning: web-server #{config['web-server']} unknown.  Use 'web-server=external' to disable."
    end
    
    server_class.start(self,foreground)
  end
  
  # Stop application
  def stop
    return unless File.directory?(install_directory)
    
    server_class = RailsInstaller::WebServer.servers[config['web-server']]
    if not server_class
      message "** warning: web-server #{config['web-server']} unknown.  Use 'web-server=external' to disable."
    end
    
    server_class.stop(self)
  end
  
  # Backup the database
  def backup_database
    db_class = RailsInstaller::Database.dbs[config['database']]
    db_class.backup(self)
  end
  
  # Restore the database
  def restore_database(filename)
    db_class = RailsInstaller::Database.dbs[config['database']]
    in_directory install_directory do
      db_class.restore(self, filename)
    end
  end

  # Copy files from the source directory to the target directory.
  def copy_files
    message "Checking for existing #{@@app_name.capitalize} install in #{install_directory}"
    files_yml = File.join(install_directory,'installer','files.yml')
    old_files = read_yml(files_yml) rescue Hash.new
    
    message "Reading files from #{source_directory}"
    new_files = sha1_hash_directory_tree(source_directory)
    new_files.delete('/config/database.yml') # Never copy this.
    
    # Next, we compare the original install hash to the current hash.  For each
    # entry:
    #
    # - in new_file but not in old_files: copy
    # - in old files but not in new_files: delete
    # - in both, but hash different: copy
    # - in both, hash same: don't copy
    #
    # We really should add a third hash (existing_files) and compare against that
    # so we don't overwrite changed files.

    added, changed, deleted, same = hash_diff(old_files, new_files)
    
    if added.size > 0
      message "Copying #{added.size} new files into #{install_directory}"
      added.keys.sort.each do |file|
        message " copying #{file}"
        copy_one_file(file)
      end
    end
    
    if changed.size > 0
      message "Updating #{changed.size} files in #{install_directory}"
      changed.keys.sort.each do |file|
        message " updating #{file}"
        copy_one_file(file)
      end
    end
    
    if deleted.size > 0
      message "Deleting #{deleted.size} files from #{install_directory}"
      
      deleted.keys.sort.each do |file|
        message " deleting #{file}"
        rm(File.join(install_directory,file)) rescue nil
      end
    end
    
    write_yml(files_yml,new_files)
  end

  # Copy one file from source_directory to install_directory, creating
  # directories as needed.
  def copy_one_file(filename)
    source_name = File.join(source_directory,filename)
    install_name = File.join(install_directory,filename)
    dir_name = File.dirname(install_name)
    
    mkdir_p(dir_name)
    cp(source_name,install_name,:preserve => true)
  end
  
  # Compute the different between two hashes.  Returns four hashes,
  # one contains the keys that are in 'b' but not in 'a' (added entries),
  # the next contains keys that are in 'a' and 'b', but have different values
  # (changed).  The third contains keys that are in 'b' but not 'a' (added).
  # The final hash contains items that are the same in each.
  def hash_diff(a, b)
    added = {}
    changed = {}
    deleted = {}
    same = {}
    
    seen = {}
    
    a.each_key do |k|
      seen[k] = true
      
      if b.has_key? k
        if b[k] == a[k]
          same[k] = true
        else
          changed[k] = true
        end
      else
        deleted[k] = true
      end
    end
    
    b.each_key do |k|
      unless seen[k]
        added[k] = true
      end
    end
    
    [added, changed, deleted, same]
  end
  
  # Decide which Rails version to freeze
  def rails_version_to_freeze
    if @@rails_version
      return "= #{@@rails_version}"
    else
      specs = Gem.source_index.find_name(app_name,["= #{@install_version}"])
      unless specs.to_a.size > 0
        raise InstallFailed, "Can't locate version #{@install_version.first}!"
      end
          
      rails_dep = specs.first.dependencies.detect {|a| a.name=='rails'}
      version = rails_dep.version_requirements.to_s
      return version
    end
  end
  
  # Freeze to a specific version of Rails gems.
  def freeze_rails
    new_version = rails_version_to_freeze

    version_file = File.join(install_directory,'vendor','rails-version')
    vendor_rails = File.join(install_directory,'vendor','rails')
    
    old_version = File.read(version_file).chomp rescue nil
    
    if new_version == old_version
      return
    elsif old_version != nil
      rm_rf(vendor_rails)
    end

    mkdir_p(vendor_rails)
    
    package_map = {
      'rails' => File.join(vendor_rails,'railties'),
      'actionmailer' => File.join(vendor_rails,'actionmailer'),
      'actionpack' => File.join(vendor_rails,'actionpack'),
      'actionwebservice' => File.join(vendor_rails,'actionwebservice'),
      'activerecord' => File.join(vendor_rails,'activerecord'),
      'activesupport' => File.join(vendor_rails,'activesupport'),
    }
    
    specs = Gem.source_index.find_name('rails',[new_version])
    
    unless specs.to_a.size > 0
      raise InstallFailed, "Can't locate Rails #{new_version}!"
    end
    
    copy_gem(specs.first, package_map[specs.first.name])
    
    specs.first.dependencies.each do |dep|
      next unless package_map[dep.name]
      
      dep_spec = Gem.source_index.find_name(dep.name,[dep.version_requirements.to_s])
      if dep_spec.size == 0
        raise InstallFailed, "Can't locate dependency #{dep.name} #{dep.version_requirements.to_s}"
      end
      
      copy_gem(dep_spec.first, package_map[dep.name])
    end
    
    File.open(version_file,'w') do |f|
      f.puts @@rails_version
    end
  end
  
  # Copy a specific gem's contents.
  def copy_gem(spec, destination)
    message("copying #{spec.name} #{spec.version} to #{destination}")
    cp_r("#{spec.full_gem_path}/.",destination)
  end
  
  # Create all default config files
  def create_default_config_files
    create_default_database_yml
  end
  
  # Create the default database.yml
  def create_default_database_yml
    db_class = RailsInstaller::Database.dbs[config['database']]
    db_class.database_yml(self)
  end
  
  # Clean up file and directory permissions.
  def fix_permissions
    unless RUBY_PLATFORM =~ /mswin32/
      message "Making scripts executable"
      chmod 0555, File.join(install_directory,'public','dispatch.fcgi')
      chmod 0555, File.join(install_directory,'public','dispatch.cgi')
      chmod 0555, Dir[File.join(install_directory,'script','*')]
    end
  end
  
  # Create required directories, like tmp
  def create_directories
    mkdir_p(File.join(install_directory,'tmp','cache'))
    chmod(0755, File.join(install_directory,'tmp','cache'))
    mkdir_p(File.join(install_directory,'tmp','session'))
    mkdir_p(File.join(install_directory,'tmp','sockets'))
    mkdir_p(File.join(install_directory,'log'))
    File.open(File.join(install_directory,'log','development.log'),'w')
    File.open(File.join(install_directory,'log','production.log'),'w')
    File.open(File.join(install_directory,'log','testing.log'),'w')
  end
  
  # Create the initial SQLite database
  def create_initial_database
    db_class = RailsInstaller::Database.dbs[config['database']]
    in_directory(install_directory) do
      db_class.create(self)
    end
  end
  
  # Get the current schema version
  def get_schema_version
    File.read(File.join(install_directory,'db','schema_version')).to_i rescue 0
  end
  
  # The path to the installed config file
  def config_file
    File.join(install_directory,'installer','rails_installer.yml')
  end

  # The path to the config file that comes with the GEM
  def backup_config_file
    File.join(source_directory,'installer','rails_installer_defaults.yml')
  end
  
  # Pick a default port number
  def set_initial_port_number
    config['port-number'] ||= (rand(1000)+4000)
  end
  
  # Pre-migrate the database.  This checks to see if we're downgrading to an
  # earlier version of our app, and runs 'rake migrate VERSION=...' to
  # downgrade the database.
  def pre_migrate_database
    old_schema_version = get_schema_version
    new_schema_version = File.read(File.join(source_directory,'db','schema_version')).to_i
    
    return unless old_schema_version > 0
     
    # Are we downgrading?
    if old_schema_version > new_schema_version
      message "Downgrading schema from #{old_schema_version} to #{new_schema_version}"
      
      in_directory install_directory do
        cmd = "rake -s db:migrate VERSION=#{new_schema_version}"
        cmd = 'cmd.exe /c ' + cmd if RUBY_PLATFORM =~ /mswin32/
        unless system(cmd)
          raise InstallFailed, "Downgrade migrating from #{old_schema_version} to #{new_schema_version} failed."
        end
      end
    end
  end
  
  # Migrate the database
  def migrate
    message "Migrating #{@@app_name.capitalize}'s database to newest release"
    
    in_directory install_directory do
      cmd = "rake -s db:migrate"
      cmd = 'cmd.exe /c ' + cmd if RUBY_PLATFORM =~ /mswin32/
      unless system(cmd)
        raise InstallFailed, "Migration failed"
      end
    end
  end

  # Run Rails tests.  This helps verify that we have a clean install
  # with all dependencies.  This cuts down on a lot of bug reports.
  def run_rails_tests
    message "Running tests.  This may take a minute or two"
    
    in_directory install_directory do
      if system_silently("rake -s test")
        message "All tests pass.  Congratulations."
      else
        message "***** Tests failed *****"
        message "** Please run 'rake test' by hand in your install directory."
        message "** Report problems to #{@@support_location}."
        message "***** Tests failed *****"
      end
    end
  end

  # Find all files in a directory tree and return a Hash containing sha1
  # hashes of all files.
  def sha1_hash_directory_tree(directory, prefix='', hash={})
    Dir.entries(directory).each do |file|
      next if file =~ /^\./
      pathname = File.join(directory,file)
      if File.directory?(pathname)
        sha1_hash_directory_tree(pathname, File.join(prefix,file), hash)
      else
        hash[File.join(prefix,file)] = Digest::SHA1.hexdigest(File.read(pathname))
      end
    end
    
    hash
  end

  # Save config settings
  def save
    write_yml(config_file,@config)
  end
  
  # Load a yaml file
  def read_yml(filename)
    YAML.load(File.read(filename))
  end
  
  # Save a yaml file.
  def write_yml(filename,object)
    File.open(filename,'w') do |f|
      f.write(YAML.dump(object))
    end
  end
  
  # Locate the source directory for a specific Version
  def find_source_directory(gem_name, version=nil)
    if version == 'cwd'
      return Dir.pwd
    elsif version
      version_array = ["= #{version}"]
    else
      version_array = ["> 0.0.0"]
    end
    
    specs = Gem.source_index.find_name(gem_name,version_array)
    unless specs.to_a.size > 0
      raise InstallFailed, "Can't locate version #{version}!"
    end
    
    @install_version = specs.last.version
    message "Installing #{app_name} #{@install_version}"
    
    specs.last.full_gem_path
  end
  
  # Call +system+, ignoring all output.
  def system_silently(command)
    if RUBY_PLATFORM =~ /mswin32/
      null = 'NUL:'
    else
      null = '/dev/null'
    end
    
    system("#{command} > #{null} 2> #{null}")
  end
  
  # Expand configuration template files.
  def expand_template_files
    rails_host = config['bind-address'] || `hostname`.chomp
    rails_port = config['port-number'].to_s
    rails_url = "http://#{rails_host}:#{rails_port}"
    Dir[File.join(install_directory,'installer','*.template')].each do |template_file|
      output_file = template_file.gsub(/\.template/,'')
      next if File.exists?(output_file) # don't overwrite files

      message "expanding #{File.basename(output_file)} template"
      
      text = File.read(template_file).gsub(/\$RAILS_URL/,rails_url).gsub(/\$RAILS_HOST/,rails_host).gsub(/\$RAILS_PORT/,rails_port)
      
      File.open(output_file,'w') do |f|
        f.write text
      end
    end
  end
  
  # Execute a command-line command
  def execute_command(*args)
    if args.size < 2
      display_help
      exit(1)
    end
    
    command_class = Command.commands[args.first]
    
    if command_class
      command_class.command(self,*(args[2..-1]))
    else
      display_help
      exit(1)
    end
  end
  
  # Display help.
  def display_help(error=nil)
    STDERR.puts error if error
    
    commands = Command.commands.keys.sort
    commands.each do |cmd|
      cmd_class = Command.commands[cmd]
      flag_help = cmd_class.flag_help_text.gsub(/APPNAME/,app_name)
      help = cmd_class.help_text.gsub(/APPNAME/,app_name)
      
      STDERR.puts "  #{app_name} #{cmd} DIRECTORY #{flag_help}"
      STDERR.puts "    #{help}"
    end
  end
  
  def is_valid_rails_directory?
    valid = false
    in_directory install_directory do
      valid = File.exists?('config/database.yml') and
        File.directory?('app') and
        File.directory?('app/models') and
        File.directory?('vendor')
    end

    valid
  end
  
end

# Run a block inside of a specific directory.  Chdir into the directory
# before executing the block, then chdir back to the original directory
# when the block exits.
def in_directory(directory)
  begin
    old_dir = Dir.pwd
    Dir.chdir(directory)
    value = yield
  ensure
    Dir.chdir(old_dir)
  end
  
  return value
end

