class ImportExecutionJob < ApplicationJob
  queue_as :import

  def perform(site, import_id)
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        import = Import.find(import_id)
        Import.with_advisory_lock("site#{site.id}_import#{import.id}", 0) do
          begin
            ImportExecution.new(import).execute
          rescue => e
            import.status = :errored
            import.error_message = e.message
            import.save!
            Rails.logger.error(e.message)
            Rails.logger.error(e.backtrace.map(&:to_s).join("\n"))
          else
            GroupMembershipsUpdateJob.perform_later(site)
          end
        end
      end
    end
  end
end
