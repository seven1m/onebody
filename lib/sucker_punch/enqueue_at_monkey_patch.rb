module ActiveJob
  module QueueAdapters
    class SuckerPunchAdapter
      # TODO: in Rails 5 this is an INSTANCE method -- not a class method
      def self.enqueue_at(job, timestamp)
        wait = timestamp.to_i - Time.now.to_i
        JobWrapper.new.async.later(wait, job.serialize)
      end

      class JobWrapper
        def later(sec, data)
          after(sec) { perform(data) }
        end
      end
    end
  end
end
