class RailsInstaller
  
  # Parent class for command-line subcommand plugins for the installer.  Each
  # subclass must implement the +command+ class method and should provide help
  # text using the +help+ method.  Example (from Typo):
  #
  #   class SweepCache < RailsInstaller::Command
  #     help "Sweep Typo's cache"
  #
  #     def self.command(installer, *args)
  #      installer.sweep_cache
  #     end
  #   end
  #
  # This implements a +sweep_cache+ command that Typo users can access by
  # running 'typo sweep_cache /some/path'.
  #
  # Subcommands that need arguments should use both 'help' and 'flag_help',
  # and then use the +args+ parameter to find their arguments.  For example,
  # the +install+ subcommand looks like this:
  #
  #   class Install < RailsInstaller::Command
  #     help "Install or upgrade APPNAME in PATH."
  #     flag_help "[VERSION] [KEY=VALUE]..."
  #
  #     def self.command(installer, *args)
  #       version = nil
  #       args.each do |arg|
  #         ...
  #       end
  #     end
  #   end
  #
  class Command
    @@command_map = {}
    
    # The +command+ method implements this sub-command.  It's called by the
    # command-line parser when the user asks for this sub-command.
    def self.command(installer, *args)
      raise "Not Implemented"
    end
    
    # +flag_help+ sets the help text for any arguments that this sub-command
    # accepts.  It defaults to ''.
    def self.flag_help(text)
      @flag_help = text
    end
    
    # Return the flag help text.
    def self.flag_help_text
      @flag_help || ''
    end
    
    # +help+ sets the help text for this subcommand.
    def self.help(text)
      @help = text
    end
    
    # Return the help text.
    def self.help_text
      @help || ''
    end
  
    def self.inherited(sub)
      name = sub.to_s.gsub(/^.*::/,'').gsub(/([A-Z])/) do |match|
        "_#{match.downcase}"
      end.gsub(/^_/,'')

      @@command_map[name] = sub
    end
    
    def self.commands
      @@command_map
    end
    
    # The +install+ command installs the application into a specific path.
    # Optionally, the user can request a specific version to install.  If
    # the version string is 'cwd', then the current directory is used as a
    # template; otherwise it looks for the specified version number in the
    # local Gems repository.
    class Install < RailsInstaller::Command
      help "Install or upgrade APPNAME in PATH."
      flag_help "[VERSION] [KEY=VALUE]..."

      def self.command(installer, *args)
        version = nil
        args.each do |arg|
          if(arg =~ /^([^=]+)=(.*)$/)
            installer.config[$1.to_s] = $2.to_s
          else
            version = arg
          end
        end
        
        installer.install(version)
      end
    end
    
    # The +config+ command controls the installation's config
    # parameters.  Running 'installer config /some/path' will show
    # all of the config parameters for the installation in /some/path.
    # You can set params with 'key=value', or clear them with 'key='.
    class Config < RailsInstaller::Command
      help "Read or set a configuration variable"
      flag_help '[KEY=VALUE]...'

      def self.command(installer, *args)
        if args.size == 0
          installer.config.keys.sort.each do |k|
            puts "#{k}=#{installer.config[k]}"
          end
        else
          args.each do |arg|
            if(arg=~/^([^=]+)=(.*)$/)
              if $2.to_s.empty?
                installer.config.delete($1.to_s)
              else
                installer.config[$1.to_s]=$2.to_s
              end
            else
              puts installer.config[arg]
            end
          end
          installer.save
        end
      end
    end
    
    # The +start+ command starts a web server in the background for the
    # specified installation, if applicable.
    class Start < RailsInstaller::Command
      help "Start the web server in the background"

      def self.command(installer, *args)
        installer.start
      end
    end

    # The +run+ command starts a web server in the foreground.
    class Run < RailsInstaller::Command
      help "Start the web server in the foreground"
      
      def self.command(installer, *args)
        installer.start(true)
      end
    end

    # The +restart+ command stops and restarts the web server.
    class Restart < RailsInstaller::Command
      help "Stop and restart the web server."
      
      def self.command(installer, *args)
        installer.stop
        installer.start
      end
    end
    
    # The +stop+ command shuts down the web server.
    class Stop < RailsInstaller::Command
      help "Stop the web server"
      
      def self.command(installer, *args)
        installer.stop
      end
    end
    
    # The +backup+ command backs the database up into 'db/backups'.
    class Backup < RailsInstaller::Command
      help "Back up the database"
      
      def self.command(installer, *args)
        installer.backup_database
      end
    end
    
    # The +restore+ command restores a backup.
    class Restore < RailsInstaller::Command
      help "Restore a database backup"
      flag_help 'BACKUP_FILENAME'
      
      def self.command(installer, *args)
        installer.restore_database(args.first)
      end
    end
  end
end
  
