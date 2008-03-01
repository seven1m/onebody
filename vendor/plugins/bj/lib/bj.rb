unless defined? Bj 
  class Bj 
  #
  # constants and associated attrs
  #
    Bj::VERSION = "1.0.1" #unless defined? Bj::VERSION
    def self.version() Bj::VERSION end

    Bj::LIBDIR = File.expand_path(File::join(File.dirname(__FILE__), "bj")) + File::SEPARATOR unless
      defined? Bj::LIBDIR
    def self.libdir(*value) 
      unless value.empty?
        File.join libdir, *value
      else
        Bj::LIBDIR 
      end
    end

    module EXIT 
      SUCCESS = 0
      FAILURE = 1
      WARNING = 42
    end
  #
  # built-in
  #
    require "socket"
    require "yaml"
    require "thread"
    require "rbconfig"
    require "set"
    require "erb"
    require "tempfile"
  #
  # bootstrap rubygems 
  #
    begin
      require "rubygems"
    rescue LoadError
      42
    end
  #
  # rubyforge/remote
  #
    require "active_record"
  #
  # rubyforge/remote or local/lib 
  #
    #%w[ attributes systemu orderedhash ].each do |lib|
    %w[ systemu orderedhash ].each do |lib|
      begin
        require lib
      rescue
        require libdir(lib)
      end
    end
  #
  # local 
  #
    load libdir("attributes.rb")
    load libdir("stdext.rb")
    load libdir("util.rb")
    load libdir("errors.rb")
    load libdir("logger.rb")
    load libdir("bj.rb")
    load libdir("joblist.rb")
    load libdir("table.rb")
    load libdir("runner.rb")
    load libdir("api.rb")
  #
  # an imperfect reloading hook - because neither rails' plugins nor gems provide one, sigh...
  #
    def self.reload!
      background = nil
      ::Object.module_eval do
        background = Bj.runner.background
        remove_const :Bj rescue nil
        remove_const :BackgroundJob rescue nil
      end
      returned = load __FILE__ rescue nil
      Bj.runner.background = background if background
      returned
    end
  end

  BackgroundJob = Bj
end
