class ImportParserJob < ActiveJob::Base
  queue_as :import

  def perform(site, import_id, data, strategy_name)
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        parser = ImportParser.new(
          import:        Import.find(import_id),
          data:          data,
          strategy_name: strategy_name
        )
        parser.parse
      end
    end
  end
end
