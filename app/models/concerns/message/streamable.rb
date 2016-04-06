require 'active_support/concern'

module Concerns
  module Message
    module Streamable
      extend ActiveSupport::Concern

      included do
        after_create :create_as_stream_item
        after_update :update_stream_items
        after_destroy { StreamItem.destroy_all(streamable_type: 'Message', streamable_id: id) }
      end
      def create_as_stream_item
        return unless streamable?
        StreamItem.create!(
          title:           subject,
          body:            html_body || body,
          text:            html_body.nil?,
          person_id:       person_id,
          group_id:        group_id,
          streamable_type: 'Message',
          streamable_id:   id,
          created_at:      created_at,
          shared:          group.present?
        )
      end

      def update_stream_items
        return unless streamable?
        StreamItem.where(streamable_type: 'Message', streamable_id: id)
                  .update_all(title: subject,
                              body:  html_body || body,
                              text:  html_body.nil?)
      end

      def streamable?
        person_id && !to_person_id && group
      end
    end
  end
end
