class Bj
  class Runner
    class Background
      def self.for(*a, &b) new(*a, &b) end

      attribute "command"
      attribute "thread"
      attribute "pid"

      def initialize command
        @command = command
        @thread = new_thread
      end

      def inspect
        {
          "command" => command,
          "pid" => pid,
        }.inspect
      end


# TODO - auto start runner?

      def new_thread 
        this = self
        Thread.new do
          Thread.current.abort_on_exception = true
          loop do
            cleanup = lambda{}

            IO.popen command, "r+" do |pipe|
              this.pid = pid = pipe.pid
              cleanup = lambda do
                cleanup = lambda{}
                begin; Process.kill(Runner.kill_signal, pid); rescue Exception; 42; end
              end
              at_exit &cleanup
              Process.wait
            end

            Bj.logger.error{ "#{ command } failed with #{ $?.inspect }" } unless
              [0, 42].include?($?.exitstatus)

            cleanup.call

            sleep 42
          end
        end
      end
    end

    module ClassMethods
      attribute("thread"){ Thread.current }
      attribute("hup_signal"){ Signal.list.keys.index("HUP") ? "HUP" : "ABRT" }
      attribute("hup_signaled"){ false }
      attribute("kill_signal"){ "TERM" }
      attribute("kill_signaled"){ false }

      def tickle
        return nil if Bj.config[Runner.no_tickle_key]
        ping or start
      end

      def ping
        begin
          pid = nil
          uri = nil
          process = nil
          Bj.transaction do
            pid = Bj.config[Runner.key(Process.pid)] || Bj.config[Runner.key]
            uri = Bj.config["#{ pid }.uri"]
            process =
              if uri
                require "drb"
                # DRb.start_service "druby://localhost:0"
                DRbObject.new(nil, uri)
              else
                Process
              end
          end
          return nil unless pid
          pid = Integer pid
          begin
            process.kill Runner.hup_signal, pid
            pid
          rescue Exception => e
            false
          end
        rescue Exception => e
          false
        end
      end

      def key ppid = 0
        ppid ||= 0
        "#{ Bj.rails_env }.#{ ppid }.pid"
      end

      def no_tickle_key 
        "#{ Bj.rails_env }.no_tickle"
      end

      def start options = {}
        options.to_options!
        background.delete Bj.rails_env if options[:force]
        background[Bj.rails_env] ||= Background.for(command)
      end

      def background
        @background ||= Hash.new
      end

      def background= value
        @background ||= value 
      end

      def command
        "#{ Bj.ruby } " + %W[
          #{ Bj.script }
          run 
          --forever 
          --redirect=#{ log }
          --ppid=#{ Process.pid }
          --rails_env=#{ Bj.rails_env }
          --rails_root=#{ Bj.rails_root }
        ].map{|word| word.inspect}.join(" ")
      end

      def log
        File.join logdir, "bj.#{ Bj.hostname }.#{ Bj.rails_env }.log"
      end

      def logdir
        File.join File.expand_path(Bj.rails_root), 'log'
      end

      def run options = {}, &block
        new(options, &block).run
      end 
    end
    send :extend, ClassMethods

    module Instance_Methods
      attribute "options"
      attribute "block"

      def initialize options = {}, &block
        options.to_options!
        @options, @block = options, block
      end

      def run
        wait = options[:wait] || 42
        limit = options[:limit]
        forever = options[:forever]

        limit = false if forever
        wait = Integer wait
        loopno = 0

        Runner.thread = Thread.current
        Bj.chroot

        register or exit!(EXIT::WARNING)

        Bj.logger.info{ "STARTED" }
        at_exit{ Bj.logger.info{ "STOPPED" } }

        fill_morgue
        install_signal_handlers

        loop do
          ping_parent

          loopno += 1
          break if(limit and loopno > limit)

          archive_jobs

          catch :no_jobs do
            loop do
              job = thread = stdout = stderr = nil

              Bj.transaction(options) do
                now = Time.now

                job = Bj::Table::Job.find :first,
                                          :conditions => ["state = ? and submitted_at <= ?", "pending", now],
                                          :order => "priority DESC, submitted_at ASC", 
                                          :limit => 1,
                                          :lock => true
                throw :no_jobs unless job


                Bj.logger.info{ "#{ job.title } - started" }

                command = job.command
                env = job.env || {}
                stdin = job.stdin || ''
                stdout = job.stdout || ''
                stderr = job.stderr || ''
                started_at = Time.now

                thread = Util.start command, :cwd=>Bj.rails_root, :env=>env, :stdin=>stdin, :stdout=>stdout, :stderr=>stderr

                job.state = "running"
                job.runner = Bj.hostname
                job.pid = thread.pid
                job.started_at = started_at 
                job.save!
                job.reload
              end

              exit_status = thread.value
              finished_at = Time.now

              Bj.transaction(options) do
                job = Bj::Table::Job.find job.id 
                break unless job
                job.state = "finished"
                job.finished_at = finished_at 
                job.stdout = stdout
                job.stderr = stderr
                job.exit_status = exit_status
                job.save!
                job.reload
                Bj.logger.info{ "#{ job.title } - exit_status=#{ job.exit_status }" }
              end
            end
          end

          Runner.hup_signaled false
          wait.times do
            break if Runner.hup_signaled?
            break if Runner.kill_signaled?
            sleep 1
          end 

          break unless(limit or limit == false)
          break if Runner.kill_signaled?
        end
      end

      def ping_parent
        ppid = options[:ppid]
        return unless ppid 
        begin
          Process.kill 0, Integer(ppid)
        rescue Errno::ESRCH
          Kernel.exit 42
        rescue Exception
          42
        end
      end

      def install_signal_handlers
        Runner.hup_signaled false
        hup_handler = nil
        hup_handler =
          trap Runner.hup_signal do |*a|
            begin
              Runner.hup_signaled true
            rescue Exception => e
              Bj.logger.error{ e } rescue nil
            end
            hup_handler.call *a rescue nil
          end

        Runner.kill_signaled false
        kill_handler = nil
        kill_handler =
          trap Runner.kill_signal do |*a|
            begin
              Runner.kill_signaled true
            rescue Exception => e
              Bj.logger.error{ e } rescue nil
            end
            kill_handler.call *a rescue nil
          end

        begin
          trap("INT"){ exit }
        rescue Exception
        end
      end

      def fill_morgue
        Bj.transaction do
          now = Time.now
          jobs = Bj::Table::Job.find :all,
                                     :conditions => ["state = 'running' and runner = ?", Bj.hostname]
          jobs.each do |job|
            if job.is_restartable?
              Bj.logger.info{ "#{ job.title } - found dead and bloated but resubmitted" }
              %w[ runner pid started_at finished_at stdout stderr exit_status ].each do |column|
                job[column] = nil
              end
              job.state = 'pending'
            else
              Bj.logger.info{ "#{ job.title } - found dead and bloated" }
              job.state = 'dead'
              job.finished_at = now
            end
            job.save!
          end
        end
      end

      def archive_jobs
        Bj.transaction do
          now = Time.now
          too_old = now - Bj.ttl
          jobs = Bj::Table::Job.find :all,
                                     :conditions => ["(state = 'finished' or state = 'dead') and submitted_at < ?", too_old]
          jobs.each do |job|
            Bj.logger.info{ "#{ job.title } - archived" }
            hash = job.to_hash.update(:archived_at => now)
            Bj::Table::JobArchive.create! hash 
            job.destroy
          end
        end
      end

      def register
        Bj.transaction do
          pid = Bj.config[key]
          return false if Util.alive?(pid)
          Bj.config[key] = Process.pid
          unless Bj.util.ipc_signals_supported? # not winblows
            require "drb"
            DRb.start_service "druby://localhost:0", Process
            Bj.config["#{ Process.pid }.uri"] = DRb.uri 
          end
        end
        at_exit{ unregister }
        true
      rescue Exception
        false
      end

      def unregister
        Bj.transaction do
          Bj.config.delete key
        end
        true
      rescue Exception
        false
      end

      def key
        @key ||= ( options[:ppid] ? Runner.key(options[:ppid]) : Runner.key )
      end
    end
    send :include, Instance_Methods
  end
end
