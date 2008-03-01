class Bj
  module ClassMethods
    attribute("rails_root"){ Util.const_or_env("RAILS_ROOT"){ "." } }
    attribute("rails_env"){ Util.const_or_env("RAILS_ENV"){ "development" } }
    attribute("database_yml"){ File.join rails_root, "config", "database.yml" }
    attribute("configurations"){ YAML::load(ERB.new(IO.read(database_yml)).result) }
    attribute("tables"){ Table.list }
    attribute("hostname"){ Socket.gethostname }
    attribute("logger"){ Bj::Logger.off STDERR }
    attribute("ruby"){ Util.which_ruby }
    attribute("rake"){ Util.which_rake }
    attribute("script"){ Util.find_script "bj" }
    attribute("ttl"){ Integer(Bj::Table::Config["ttl"] || (twenty_four_hours = 24 * 60 * 60)) }
    attribute("table"){ Table }
    attribute("config"){ table.config }
    attribute("util"){ Util }
    attribute("runner"){ Runner }
    attribute("joblist"){ Joblist }
    attribute("default_path"){ %w'/bin /usr/bin /usr/local/bin /opt/local/bin'.join(File::PATH_SEPARATOR) }

    def transaction options = {}, &block
      options.to_options!

      cur_rails_env = Bj.rails_env.to_s
      new_rails_env = options[:rails_env].to_s

      cur_spec = configurations[cur_rails_env]
      table.establish_connection(cur_spec) unless table.connected?

      if(new_rails_env.empty? or cur_rails_env == new_rails_env) 
        table.transaction{ block.call(table.connection) }
      else
        new_spec = configurations[new_rails_env]
        table.establish_connection(new_spec)
        Bj.rails_env = new_rails_env
        begin
          table.transaction{ block.call(table.connection) }
        ensure
          table.establish_connection(cur_spec)
          Bj.rails_env = cur_rails_env
        end
      end
    end

    def chroot options = {}, &block
      if defined? @chrooted and @chrooted
        return(block ? block.call(@chrooted) : @chrooted)
      end
      if block
        begin
          chrooted = @chrooted
          Dir.chdir(@chrooted = rails_root) do
            raise RailsRoot, "<#{ Dir.pwd }> is not a rails root" unless Util.valid_rails_root?(Dir.pwd)
            block.call(@chrooted)
          end
        ensure
          @chrooted = chrooted 
        end
      else
        Dir.chdir(@chrooted = rails_root)
        raise RailsRoot, "<#{ Dir.pwd }> is not a rails root" unless Util.valid_rails_root?(Dir.pwd)
        @chrooted
      end
    end

    def boot
      load File.join(rails_root, "config", "boot.rb")
      load File.join(rails_root, "config", "environment.rb")
    end
  end
  send :extend, ClassMethods
end
