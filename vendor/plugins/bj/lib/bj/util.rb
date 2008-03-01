class Bj
  module Util
    module ModuleMethods
      def constant_get const, &block
        begin
          ancestors = const.split(%r/::/)
          parent = Object
          while((child = ancestors.shift))
            klass = parent.const_get child
            parent = klass
          end
          klass
        rescue
          block ? block.call : raise
        end
      end

      def const_or_env const, &block
        constant_get(const){ ENV[const] || block.call }
      end

      def spawn cmd, options = {}
        options.to_options!
        logger = options.has_key?(:logger) ? options[:logger] : Bj.logger
        logger.info{ "cmd <#{ cmd }>" } if logger
        status = systemu cmd, 1=>(stdout=""), 2=>(stderr="")
        logger.info{ "status <#{ status.exitstatus }>" } if logger
        status.exitstatus.zero? or raise "#{ cmd.inspect } failed with #{ $?.inspect }"
        [ stdout, stderr ]
      end

      def start *a 
        q = Queue.new
        thread = Thread.new do
          Thread.current.abort_on_exception = true
          systemu(*a){|pid| q << pid}
        end
        pid = q.pop
        thread.singleton_class{ define_method(:pid){ pid } }
        thread
      end

      def alive pid
        return false unless pid 
        pid = Integer pid.to_s 
        Process::kill 0, pid
        true
      rescue Errno::ESRCH, Errno::EPERM
        false
      end
      alias_method "alive?", "alive"

      def which_ruby
        c = ::Config::CONFIG
        ruby = File::join(c['bindir'], c['ruby_install_name']) << c['EXEEXT']
        raise "ruby @ #{ ruby } not executable!?" unless test(?e, ruby)
        ruby
      end

      def which_rake 
        tmp = Tempfile.new Process.pid
        tmp.write "task(:foobar){ puts 42 }"
        tmp.close
        bat = spawn("rake.bat -f #{ tmp.path.inspect } foobar", :logger => false) rescue false
        bat ? "rake.bat" : "rake"
      ensure
        tmp.close! rescue nil
      end

      def ipc_signals_supported
        @ipc_signals_supported ||=
          IO.popen 'ruby', 'r+' do |ruby|
            pid = ruby.pid
            begin
              Process.kill 'TERM', pid
              true
            rescue Exception
              false
            end
          end
      end
      alias_method "ipc_signals_supported?", "ipc_signals_supported"

      def find_script basename
        path = ENV["PATH"] || ENV["path"] || Bj.default_path
        raise "no env PATH" unless path
        path = path.split File::PATH_SEPARATOR
        path.unshift File.join(Bj.rails_root, "script")
        path.each do |directory|
          script = File.join directory, basename
          return File.expand_path(script) if(test(?s, script) and test(?r, script))
        end
        raise "no #{ basename } found in #{ path.inspect }"
      end

      def valid_rails_root root = ".", expected = %w[ config script app ]
        directories = expected.flatten.compact.map{|dir| dir.to_s}
        directories.all?{|dir| test(?d, File.join(root, dir))}
      end
      alias_method "valid_rails_root?", "valid_rails_root"

      def emsg e
        m = e.message rescue ""
        c = e.class rescue Exception
        b = e.backtrace.join("\n") rescue ""
        "#{ m }(#{ c })\n#{ b }"
      end
    end
    send :extend, ModuleMethods
  end
end
