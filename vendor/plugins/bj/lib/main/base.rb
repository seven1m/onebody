module Main
  class Base
    class << self
      def wrap_run!
        const_set :RUN, instance_method(:run)

        class_eval do
          def run *a, &b
            argv.push "--#{ argv.shift }" if argv.first == 'help'
            return mode_run! if mode_given?

            status =
              catch :exit do
                begin

                  parse_parameters

                  if params['help'] and params['help'].given?
                    print usage.to_s
                    exit
                  end

                  pre_run
                  before_run
                  self.class.const_get(:RUN).bind(self).call(*a, &b)
                  after_run
                  post_run

                  finalize
                rescue Exception => e
                  handle_exception e
                end
                nil
              end

            handle_throw status
          end
        end
      end

      def method_added m
        return if @in_method_added
        super if defined? super
        @in_method_added = true
        begin
          wrap_run! if m.to_s == 'run'
        ensure
          @in_method_added = false 
        end
      end

      def self.inheritable_attribute name, &block
        block ||= lambda{}
        attribute( name ){ 
          catch :value do
            if parent?
              value = parent.send name 
              value =
                begin
                  Util.mcp value
                rescue
                  value.clone rescue value.dup
                end
              throw :value, value 
            end
            instance_eval &block
          end
        } 
      end

    # attributes
      attribute( 'name' ){ File.basename $0 } 
      attribute( 'synopsis' ){ Usage.default_synopsis(self) }
      attribute( 'description' )
      attribute( 'usage' ){ Usage.default_usage self } 
      attribute( 'modes' ){ Mode.list }
      attribute( 'mode_definitions' ){ Array.new }
      attribute( 'mode_name' ){ 'main' }
      attribute( 'parent' ){ nil }
      attribute( 'children' ){ Set.new }

      attribute( 'program' ){ File.basename $0 } 
      attribute( 'author' )
      attribute( 'version' )
      attribute( 'stdin' ){ $stdin } 
      attribute( 'stdout' ){ $stdout } 
      attribute( 'stderr' ){ $stderr } 
      attribute( 'logger' ){ stderr } 
      attribute( 'logger_level' ){ Logger::INFO } 
      attribute( 'exit_status' ){ EXIT_SUCCESS } 
      attribute( 'exit_success' ){ EXIT_SUCCESS } 
      attribute( 'exit_failure' ){ EXIT_FAILURE } 
      attribute( 'exit_warn' ){ EXIT_WARN } 
      inheritable_attribute( 'parameters' ){ Parameter::List[] }
      inheritable_attribute( 'can_has_hash' ){ Hash.new }
      inheritable_attribute( 'mixin_table' ){ Hash.new }

    # override a few attributes
      def mode_name=(value)
        @mode_name = Mode.new value
      end

      def usage *argv, &block
        usage! unless defined? @usage 
        return @usage if argv.empty? and block.nil?
        key, value, *ignored = argv
        value = block.call if block
        @usage[key.to_s] = value.to_s
      end

      def create parent = Base, *a, &b
        Class.new parent do |child|
          child.parent = parent unless parent == Base
          parent.children.add child
          child.context do
            child.class_eval &b if b
            child.default_options!
            #child.wrap_run! unless child.const_defined?(:RUN)
            mode_definitions.each do |name, block|
              klass = 
                create context do
                  mode_name name.to_s
                  module_eval &block if block
                end
              modes.add klass
            end
          end
        end
      end

      def context &block 
        @@context ||= []
        unless block 
          @@context.last
        else
          begin
            @@context.push self 
            block.call @@context.last
          ensure
            @@context.pop
          end
        end
      end

      module ::Main
        singleton_class{
          def current
            ::Main::Base.context
          end
        }
      end

      def fully_qualified_mode
        list = []
        ancestors.each do |ancestor|
          break unless ancestor < Base
          list << ancestor.mode_name
        end
        list.reverse[1..-1]
      end

      def run(&b) define_method(:run, &b) end

      def new(*a, &b)
        allocate.instance_eval do
          pre_initialize
          before_initialize
          main_initialize *a, &b
          initialize
          after_initialize
          post_initialize
          self
        end
      end
    end

    module DSL
      def parameter *a, &b
        (parameters << Parameter.create(:parameter, *a, &b)).last
      end

      def option *a, &b
        (parameters << Parameter.create(:option, *a, &b)).last
      end
      alias_method 'opt', 'option'
      alias_method 'switch', 'option'

      def default_options!
        option 'help', 'h' unless parameters.has_option?('help', 'h')
      end

      def argument *a, &b
        (parameters << Parameter.create(:argument, *a, &b)).last
      end
      alias_method 'arg', 'argument'

      def keyword *a, &b
        (parameters << Parameter.create(:keyword, *a, &b)).last
      end
      alias_method 'kw', 'keyword'

      def environment *a, &b
        (parameters << Parameter.create(:environment, *a, &b)).last
      end
      alias_method 'env', 'environment'

=begin
      def mode name, &b
        klass = 
          create context do
            mode_name name.to_s
            module_eval &b if b
          end
        modes.add klass
      end
=end

      def mode name, &b
        mode_definitions << [name, b]
      end

      def can_has ptype, *a, &b
        key = a.map{|s| s.to_s}.sort_by{|s| -s.size }.first
        can_has_hash.update key => [ptype, a, b]
        key
      end

      def has key, *keys 
        keys = [key, *keys].flatten.compact.map{|k| k.to_s}
        keys.map do |key|
          ptype, a, b = can_has_hash[key]
          abort "yo - can *not* has #{ key.inspect }!?" unless(ptype and a and b)
          send ptype, *a, &b
          key
        end
      end

      def mixin name, *names, &block
        names = [name, *names].flatten.compact.map{|name| name.to_s}
        if block
          names.each do |name|
            mixin_table[name] = block
          end
        else
          names.each do |name|
            module_eval &mixin_table[name]
          end
        end
      end

## TODO - for some reason these hork the usage!

      %w[ examples samples api ].each do |chunkname|
        module_eval <<-code
          def #{ chunkname } *a, &b 
            txt = b ? b.call : a.join("\\n")
            usage['#{ chunkname }'] = txt
          end
        code
      end
      alias_method 'example', 'examples'
      alias_method 'sample', 'samples'
    end
    extend DSL

    attribute 'argv'
    attribute 'env'
    attribute 'params'
    attribute 'logger'
    attribute 'stdin'
    attribute 'stdout'
    attribute 'stderr'

    %w( 
      program name synopsis description author version
      exit_status exit_success exit_failure exit_warn
      logger_level
      usage
    ).each{|a| attribute(a){ self.class.send a}}

    %w( parameters param ).each do |dst|
      alias_method "#{ dst }", "params"
      alias_method "#{ dst }=", "params="
      alias_method "#{ dst }?", "params?"
    end

    %w( debug info warn fatal error ).each do |m|
      module_eval <<-code
        def #{ m } *a, &b
          logger.#{ m } *a, &b
        end
      code
    end

=begin
=end
    def pre_initialize() :hook end
    def before_initialize() :hook end
    def main_initialize argv = ARGV, env = ENV, opts = {}
      @argv, @env, @opts = argv, env, opts
      setup_finalizers
      setup_io_restoration
      setup_io_redirection
      setup_logging
    end
    def initialize() :hook end
    def after_initialize() :hook end
    def post_initialize() :hook end

    def setup_finalizers
      @finalizers = finalizers = []
      ObjectSpace.define_finalizer(self) do
        while((f = finalizers.pop)); f.call; end
      end
    end

    def finalize
      while((f = @finalizers.pop)); f.call; end
    end

    def setup_io_redirection
      self.stdin = @opts['stdin'] || @opts[:stdin] || self.class.stdin
      self.stdout = @opts['stdout'] || @opts[:stdout] || self.class.stdout
      self.stderr = @opts['stderr'] || @opts[:stderr] || self.class.stderr
    end

    def setup_logging
      log = self.class.logger || stderr
      self.logger = log
    end
    def logger= log
      unless(defined?(@logger) and @logger == log)
        case log 
          when ::Logger, Logger
            @logger = log
          when IO, StringIO
            @logger = Logger.new log 
            @logger.level = logger_level 
          else
            @logger = Logger.new *log
            @logger.level = logger_level 
        end
      end
      @logger
    end

    def setup_io_restoration
      [STDIN, STDOUT, STDERR].each do |io|
        dup = io.dup and @finalizers.push lambda{ io.reopen dup }
      end
    end

    def stdin= io
      unless(defined?(@stdin) and (@stdin == io))
        @stdin =
          if io.respond_to? 'read'
            io
          else
            fd = open io.to_s, 'r+'
            @finalizers.push lambda{ fd.close }
            fd
          end
        begin
          STDIN.reopen @stdin
        rescue
          $stdin = @stdin
          ::Object.const_set 'STDIN', @stdin
        end
      end
    end

    def stdout= io
      unless(defined?(@stdout) and (@stdout == io))
        @stdout =
          if io.respond_to? 'write'
            io
          else
            fd = open io.to_s, 'w+'
            @finalizers.push lambda{ fd.close }
            fd
          end
        STDOUT.reopen @stdout rescue($stdout = @stdout)
      end
    end

    def stderr= io
      unless(defined?(@stderr) and (@stderr == io))
        @stderr =
          if io.respond_to? 'write'
            io
          else
            fd = open io.to_s, 'w+'
            @finalizers.push lambda{ fd.close }
            fd
          end
        STDERR.reopen @stderr rescue($stderr = @stderr)
      end
    end
    
    def pre_parse_parameters() :hook end
    def before_parse_parameters() :hook end
    def parse_parameters
      pre_parse_parameters

      self.class.parameters.parse @argv, @env
      @params = Parameter::Table.new
      self.class.parameters.each{|p| @params[p.name.to_s] = p}

      post_parse_parameters
    end
    def after_parse_parameters() :hook end
    def post_parse_parameters() :hook end

    def pre_run() :hook end
    def before_run() :hook end
    def run
      raise NotImplementedError, 'run not defined'
    end
    def after_run() :hook end
    def post_run() :hook end

    def mode_given?
      begin
        modes.size > 0 and
        argv.size > 0 and
        modes.find_by_mode(argv.first)
      rescue Mode::Ambiguous
        true
      end
    end
    def mode_run!
      mode = modes.find_by_mode argv.shift
      klass = modes[mode] or abort "bad mode <#{ mode }>"
      main = klass.new @argv, @env, @opts
      main.mode = mode
      main.run
    end
    def modes
      self.class.modes
    end
    attribute 'mode'

    def help! status = 0
      print usage.to_s
      exit(status)
    end

    def abort message = 'exit'
      raise SystemExit.new(message)
    end

    def handle_exception e
      if e.respond_to?(:error_handler_before)
        fcall(e, :error_handler_before, self)
      end

      if e.respond_to?(:error_handler_instead)
        fcall(e, :error_handler_instead, self)
      else
        if e.respond_to? :status
          exit_status(( e.status ))
        end

        if Softspoken === e or SystemExit === e
          quiet = ((SystemExit === e and e.message.respond_to?('abort')) or # see main/stdext.rb
                  (SystemExit === e and e.message == 'exit'))
          stderr.puts e.message unless quiet
        else
          fatal{ e }
        end
      end

      if e.respond_to?(:error_handler_after)
        fcall(e, :error_handler_after, self)
      end

      exit_status(( exit_failure )) if exit_status == exit_success
      exit_status(( Integer(exit_status) rescue(exit_status ? 0 : 1) ))
      exit exit_status
    end

    def fcall obj, m, *argv, &block
      m = obj.method m
      arity = m.arity
      if arity >= 0
        argv = argv[0, arity]
      else
        arity = arity.abs - 1
        argv = argv[0, arity] + argv[arity .. -1]
      end
      m.call *argv, &block
    end

    def handle_throw status
      exit(( Integer(status) rescue 0 ))
    end

    %w[ before instead after ].each do |which|
      module_eval <<-code
        def error_handler_#{ which } *argv, &block
          block.call *argv
        end
      code
    end

    def instance_eval_block *argv, &block
      sc =
        class << self
          self
        end
      sc.module_eval{ define_method '__instance_eval_block', &block }
      fcall self, '__instance_eval_block', *argv, &block
    end
  end
end
