class Bj
#
# the api exposes nearly all the bj code you'll likely need, with the
# exception of accessing the job table for searching, which is done using
#
# eg.
#
#   Bj.table.job.find :all
#
  module API
  #
  # submit jobs for background processing.  'jobs' can be a string or array of
  # strings.  options are applied to each job in the 'jobs', and the list of
  # submitted jobs is always returned.  options (string or symbol) can be
  #
  #   :rails_env => production|development|key_in_database_yml 
  #                 when given this keyword causes bj to submit jobs to the
  #                 specified database.  default is RAILS_ENV.
  #
  #   :priority => any number, including negative ones.  default is zero.
  #
  #   :tag => a tag added to the job.  simply makes searching easier.
  #
  #   :env => a hash specifying any additional environment vars the background
  #           process should have.
  #
  #   :stdin => any stdin the background process should have.
  #
  # eg:
  #
  #   jobs = Bj.submit 'echo foobar', :tag => 'simple job'
  #
  #   jobs = Bj.submit '/bin/cat', :stdin => 'in the hat', :priority => 42
  #
  #   jobs = Bj.submit './script/runner ./scripts/a.rb', :rails_env => 'production'
  #
  #   jobs = Bj.submit './script/runner /dev/stdin', :stdin => 'p RAILS_ENV', :tag => 'dynamic ruby code'
  #
  #   jobs = Bj.submit array_of_commands, :priority => 451 
  #
  # when jobs are run, they are run in RAILS_ROOT.  various attributes are
  # available *only* once the job has finished.  you can check whether or not
  # a job is finished by using the #finished method, which simple does a
  # reload and checks to see if the exit_status is non-nil.
  #
  # eg:
  #
  #   jobs = Bj.submit list_of_jobs, :tag => 'important'
  #   ...
  #   
  #   jobs.each do |job|
  #     if job.finished?
  #       p job.exit_status
  #       p job.stdout
  #       p job.stderr
  #     end
  #   end
  #
  #
    def submit jobs, options = {}, &block
      options.to_options!
      Bj.transaction(options) do
        table.job.submit jobs, options, &block
      end
    ensure
      Bj.runner.tickle unless options[:no_tickle]
    end
  #
  # this method changes the context under which bj is operating.  a context is
  # a RAILS_ENV.  the method accepts a block and it used to alter the
  # behaviour of the bj lib on a global scale such that all operations,
  # spawning of background runnner processes, etc, occur in that context.
  #
  # eg:
  #
  #  Bj.in :production do
  #    Bj.submit './script/runner ./scripts/facebook_notification.rb'
  #  end
  #
  #  Bj.in :development do
  #    Bj.submit 'does_this_eat_memory.exe'
  #  end
  #
    def in rails_env = Bj.rails_env, &block
      transaction(:rails_env => rails_env.to_s, &block)
    end
  #
  # list simply returns a list of all jobs in the job table
  #
    def list options = {}, &block
      options.to_options!
      Bj.transaction(options) do
        options.delete :rails_env
        table.job.find(:all, options)
      end
    end
  #
  #
  #
    def run options = {}
      runner.run options
    end
  #
  # generate a migration and migrate a database (production/development/etc)
  #
    def setup options = {}
      options.to_options!
      chroot do
        generate_migration options
        migrate options
      end
    end
  #
  # generate_migration, suprisingly, generates the single migration needed for
  # bj.  you'll notice the the migration is very short as the migration
  # classes themselves are inner classes of the respective bj table class.
  # see lib/bj/table.rb for details.
  #
    def generate_migration options = {}
      options.to_options!
      chroot do
        before = Dir.glob "./db/migrate/*"
        n = Dir.glob("./db/migrate/*_bj_*").size
        classname = "BjMigration#{ n }"
        util.spawn "#{ Bj.ruby } ./script/generate migration #{ classname }", options rescue nil
        after = Dir.glob "./db/migrate/*"
        candidates = after - before
        case candidates.size
          when 0
            false
          when 1
            generated = candidates.first
            open(generated, "w"){|fd| fd.puts Bj.table.migration_code(classname)}
            Bj.logger.info{ "generated <#{ generated }>" }
            generated
          else
            raise "ambiguous migration <#{ candidates.inspect }>"
        end
      end
    end
  #
  # migrate a database (production|development|etc)
  #
    def migrate options = {}
      options.to_options!
      chroot do
        util.spawn "rake RAILS_ENV=#{ Bj.rails_env } db:migrate", options
      end
    end
  #
  # install plugin into this rails app 
  #
    def plugin options = {}
      options.to_options!
      chroot do
        util.spawn "#{ Bj.ruby } ./script/plugin install http://codeforpeople.rubyforge.org/svn/rails/plugins/bj --force", options
      end
    end
  end
  send :extend, API
end
