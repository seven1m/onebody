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
        attr_accessor :dont_stream
      end

      def create_as_stream_item
        return if dont_stream
        item = StreamItem.create!(
          title: name,
          person_id: id,
          streamable_type: 'Person',
          streamable_id: id,
          created_at: created_at,
          shared: visible? && email.present?
        )
        return unless item_grouping_enabled?
        StreamItemGroupJob.perform_later(Site.current, item.id)
      end

      def update_stream_item
        return if dont_stream
        return unless changes_affecting_stream_item?
        return unless stream_item
        stream_item.title = name
        stream_item.shared = visible? && email.present?
        stream_item.save!
        return unless item_grouping_enabled?
        StreamItemGroupJob.perform_later(Site.current, stream_item.id)
      end

      def destroy_stream_item
        stream_item&.destroy
      end

      def item_grouping_enabled?
        !Rails.env.test?
      end

      def changes_affecting_stream_item?
        changes['first_name'] ||
          changes['last_name'] ||
          changes['suffix'] ||
          changes['deleted'] ||
          (changes['email'] || []).one?(&:blank?)
      end
    end
  end
end
