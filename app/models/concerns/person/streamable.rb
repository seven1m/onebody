require 'active_support/concern'

module Concerns
  module Person
    module Streamable
      extend ActiveSupport::Concern

      included do
        has_one :stream_item, as: :streamable
        after_create :create_as_stream_item
        after_update :update_stream_item
        after_destroy :destroy_stream_item
      end

      def create_as_stream_item
        return unless can_create_stream_item?
        StreamItem.create!(
          title: name,
          person_id: id,
          streamable_type: 'Person',
          streamable_id: id,
          created_at: created_at,
          shared: visible? && email.present?
        )
      end

      LIMIT_CONSECUTIVE_STREAM_ITEMS = 2

      def can_create_stream_item?
        previous = StreamItem.limit(LIMIT_CONSECUTIVE_STREAM_ITEMS)
                             .order(id: :desc)
                             .pluck(:streamable_type)
        previous != ['Person'] * LIMIT_CONSECUTIVE_STREAM_ITEMS
      end

      def update_stream_item
        return unless stream_item
        stream_item.title = name
        stream_item.shared = visible? && email.present?
        stream_item.save!
      end

      def destroy_stream_item
        stream_item.destroy if stream_item
      end
    end
  end
end
