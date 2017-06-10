require 'active_support/concern'

module Concerns
  module Person
    module Sharing
      extend ActiveSupport::Concern

      included do
        scope :in_group_ids, ->(ids) { joins(:memberships).where('memberships.group_id in (?)', ids) }
      end

      def in_groups(groups)
        in_group_ids(groups.map(&:id))
      end

      def small_groups
        size = Setting.get(:features, :small_group_size)
        if size == 'all'
          groups.active
        else
          groups.active.where("(select count(*) from memberships where group_id=groups.id) <= #{size.to_i}")
        end
      end

      def small_group_people
        ::Person.in_group_ids(small_groups.pluck(:id)).where('people.id != ?', id)
      end

      def sharing_with_people
        ids = sharing_with_people_ids
        ::Person.where(id: ids[:family_ids] + ids[:friend_ids] + ids[:groupy_ids].map(&:first))
      end

      def sharing_with_people_ids
        {
          family_ids: family.people.undeleted.where.not(id: id).pluck(:id),
          friend_ids: Setting.get(:features, :friends) ? friends.pluck(:id) : [],
          groupy_ids: small_group_people.pluck(:id, :group_id)
        }
      end

      def reason_sharing_with(person)
        ids = sharing_with_people_ids
        {}.tap do |reasons|
          reasons[:family] = person.family if ids[:family_ids].include?(person.id)
          reasons[:friend] = true if ids[:friend_ids].include?(person.id)
          reasons[:groups] = Group.find(ids[:groupy_ids].select { |id, _group_id| id == person.id }.map(&:last))
          reasons.delete(:groups) if reasons[:groups].empty?
        end
      end
    end
  end
end
