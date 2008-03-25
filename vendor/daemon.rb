# Ruby Daemon - http://snippets.dzone.com/posts/show/2265
# by Sharon Rosner http://hiperu.blogspot.com

# modified by Tim Morgan, 24-Mar-2008

# Usage:
# class Counter < Daemon::Base
#   def self.start
#     @a = 0
#     loop do
#       @a += 1
#     end
#   end
#   def self.stop
#     File.open('result', 'w') {|f| f.puts "a = #{@a}"}
#   end
# end
# Counter.daemonize

require 'fileutils'

module Daemon
  class Base
    def self.pid_fn
      File.join(@@working_dir, "#{name}.pid")
    end
    
    def self.daemonize(working_dir)
      @@working_dir = working_dir
      Controller.daemonize(self, @@working_dir)
    end
  end
  
  module PidFile
    def self.store(daemon, pid)
      File.open(daemon.pid_fn, 'w') {|f| f << pid}
    end
    
    def self.recall(daemon)
      IO.read(daemon.pid_fn).to_i rescue nil
    end
  end
  
  module Controller
    def self.daemonize(daemon, working_dir)
      @@working_dir = working_dir
      case !ARGV.empty? && ARGV[0]
      when 'run'
        run(daemon)
      when 'start'
        start(daemon)
      when 'stop'
        stop(daemon)
      when 'restart'
        stop(daemon)
        start(daemon)
      else
        puts "Invalid command. Please specify run, start, stop or restart."
        exit
      end
    end
    
    def self.start(daemon)
      begin
        fork do
          Process.setsid
          exit if fork
          PidFile.store(daemon, Process.pid)
          Dir.chdir @@working_dir
          File.umask 0000
          STDIN.reopen "/dev/null"
          STDOUT.reopen "/dev/null", "a"
          STDERR.reopen STDOUT
          trap("TERM") {daemon.stop; exit}
          daemon.start
        end
      rescue NotImplementedError # windows
        puts 'Windows is not supported. Try "run" instead (will run once and quit).'
      end
    end
    
    def self.run(daemon)
      daemon.run
    end
  
    def self.stop(daemon)
      if !File.file?(daemon.pid_fn)
        puts "Pid file not found. Is the daemon started?"
        exit
      end
      pid = PidFile.recall(daemon)
      FileUtils.rm(daemon.pid_fn)
      pid && Process.kill("TERM", pid) rescue puts('Process not found')
    end
  end
end
