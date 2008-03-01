class Bj
  class JobList < ::Array
    module ClassMethods
      def for jobs, options = {}
        if Joblist === jobs
          jobs.update options
          return jobs
        end
        options.to_options!
        jobs = [jobs].flatten.compact
        list = []
        jobs.each do |arg|
          list.push(
            case arg
              when String
                case arg
                  when %r/^\d+$/
                    job_from_id arg
                  else
                    job_from_string arg
                end
              when Hash
                job_from_hash arg
              when Io
                jobs_from_io arg
              when Fixnum, Bignum
                job_from_number arg
              else
                job_from_string arg
            end
          )
        end
        list.flatten!
        list.compact!
        list.map!{|job| job.reverse_merge! options}
        list
      end

      def job_from_hash arg
        arg.to_hash.to_options!
      end

      def job_from_string arg
        unless arg.strip.empty?
          { :command => arg.to_s }
        else
          nil
        end
      end

      def job_from_number arg
        id = arg.to_i
        Table::Job.find(id).to_hash
      end

      def jobs_from_io arg 
        if arg == "-"
          load_from_io STDIN
        else
          if arg.respond_to? :read
            load_from_io arg 
          else
            open(arg, "r"){|fd| load_from_io fd}
          end
        end
      end

      def load_from_io io
        list = []
        io.each do |line|
          line.strip!
          next if line.empty?
          list << job_from_string(line)
        end
        list
      end

      def jobs_from_yaml arg 
        object =
          if arg == "-"
            YAML.load STDIN
          else
            if arg.respond_to? :read
              YAML.load arg
            else
              open(arg, "r"){|fd| YAML.load fd}
            end
          end
        Joblist.for object
      end
    end
    send :extend, ClassMethods

    module InstanceMethods
      def update options = {}
        options.to_options!
        each{|job| job.update options}
      end

      def push other
        Joblist.for(other).each do |job|
          super job
        end
        self
      end
      alias_method "<<", "push"
    end
    send :include, InstanceMethods
  end

  Joblist = JobList
end
