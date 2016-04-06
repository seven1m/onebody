require 'active_support/concern'

module Concerns
  module Message
    module Sendable
      extend ActiveSupport::Concern

      included do
        attr_accessor :dont_send
        after_create :enqueue_send
      end

      def enqueue_send
        MessageSendJob.perform_later(Site.current, id) unless dont_send
      end

      def send_message
        if group
          send_to_group
        elsif to
          send_to_person(to)
        end
      end

      def send_to_person(person)
        return if person.email.nil?
        email = Notifier.full_message(person, self, id_and_code)
        email.add_message_id
        email.message_id = "<#{id_and_code}_#{email.message_id.gsub(/^</, '')}"
        email.deliver_now
      end

      def send_to_group(sent_to = [])
        return unless group
        group.people.each do |person|
          if should_send_group_email_to_person?(person, sent_to)
            send_to_person(person)
            sent_to << person.email
          end
        end
      end

      def should_send_group_email_to_person?(person, sent_to)
        person.email.present? &&
          person.email =~ VALID_EMAIL_ADDRESS &&
          group.get_options_for(person).get_email? &&
          !sent_to.include?(person.email) &&
          (members.empty? || members.include?(person))
      end
    end
  end
end
