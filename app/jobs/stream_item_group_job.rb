class StreamItemGroupJob < ApplicationJob
  queue_as :stream_item_group

  def perform(site, stream_item_id)
    Site.with_current(site) do
      base_item = StreamItem.find(stream_item_id)
      StreamItemGrouper.new(base_item).group
    end
  end
end
