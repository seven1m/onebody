class ImportPreviewJob < ApplicationJob
  queue_as :import

  def perform(site, import_id)
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        import = Import.find(import_id)
        Import.with_advisory_lock("site#{site.id}_import#{import.id}", 0) do
          begin
            ImportPreview.new(import).preview
          rescue => e
            import.status = :errored
            import.error_message = e.message
            import.save!
          end
        end
      end
    end
  end
end
