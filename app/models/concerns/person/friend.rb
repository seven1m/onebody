require 'active_support/concern'

module Concerns
  module Person
    module Friend
      extend ActiveSupport::Concern

      included do
        has_many :friendships
        has_many :friends, -> { order('people.last_name', 'people.first_name') }, class_name: 'Person', through: :friendships
        has_many :friendship_requests
        has_many :pending_friendship_requests, -> { where(rejected: false) }, class_name: 'FriendshipRequest'
        after_destroy :destroy_friendships
      end

      def request_friendship_with(person)
        if pending = pending_friendship_requests.where(from_id: person.id).first
          pending.accept
          I18n.t('friends.added_as_friend', name: person.name)
        elsif can_request_friendship_with?(person)
          friendship_requests.where(from_id: person.id, rejected: true).delete_all
          person.friendship_requests.create!(from: self)
          I18n.t('friends.request_sent', name: person.name)
        elsif friendship_waiting_on?(person)
          I18n.t('friends.already_pending', name: person.name)
        elsif friendship_rejected_by?(person)
          I18n.t('friends.cannot_request', name: person.name)
        else
          raise I18n.t('friends.unknown_state')
        end
      end

      def can_request_friendship_with?(person)
        Setting.get(:features, :friends) &&
          person != self &&
          person.family_id != family_id &&
          !friend?(person) &&
          active? &&
          person.active? &&
          person.email.present? &&
          person.friends_enabled &&
          !friendship_rejected_by?(person) &&
          !friendship_waiting_on?(person)
      end

      def friendship_rejected_by?(person)
        person.friendship_requests.where(from_id: id, rejected: true).any?
      end

      def friendship_waiting_on?(person)
        person.friendship_requests.where(from_id: id, rejected: false).any?
      end

      def friend?(person)
        friends.where('friendships.friend_id' => person.id).exists?
      end

      def destroy_friendships
        friendships.destroy_all
        friendship_requests.destroy_all
      end
    end
  end
end
