class StreamItemGroupJob < ActiveJob::Base
  queue_as :stream_item_group

  SAFETY_QUERY_LIMIT = 1000

  GROUP_ALL_BUT_FIRST = 2

  def perform(site, stream_item_id)
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        base_item = StreamItem.find(stream_item_id)
        boundary_item = StreamItem
          .where('created_at < ?', base_item.created_at)
          .where.not(streamable_type: base_item.streamable_type)
          .order(created_at: :desc)
          .first
        ids = StreamItem
          .where(streamable_type: base_item.streamable_type)
          .where('created_at <= ?', base_item.created_at)
          .where('created_at > ?', boundary_item ? boundary_item.created_at : 1.month.ago)
          .where(stream_item_group_id: nil)
          .limit(SAFETY_QUERY_LIMIT)
          .order(created_at: :desc, id: :desc)
          .pluck(:id)
        to_group = Array(ids[GROUP_ALL_BUT_FIRST..-1])
        return unless to_group.any?
        if boundary_item && boundary_item.streamable_type == 'StreamItemGroup'
          boundary_item.item_ids += to_group
        else
          StreamItem.create!(
            streamable_type: 'StreamItemGroup',
            item_ids: to_group,
            shared: true,
            is_public: true,
            created_at: StreamItem.find(to_group.last).created_at,
            context: { streamable_type: base_item.streamable_type }
          )
        end
      end
    end
  end
end
