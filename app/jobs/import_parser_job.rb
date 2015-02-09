class ImportParserJob < ActiveJob::Base
  queue_as :import

  def perform
    # TODO
  end
end
