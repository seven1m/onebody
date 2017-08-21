class ImportParserJob < ApplicationJob
  queue_as :import

  def perform(site, import_id, data, strategy_name)
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        import = Import.find(import_id)
        parser = ImportParser.new(
          import:        import,
          data:          data,
          strategy_name: strategy_name
        )
        begin
          parser.parse
        rescue => e
          import.status = :errored
          import.error_message = e.message.inspect
          import.save!
        end
      end
    end
  end
end
