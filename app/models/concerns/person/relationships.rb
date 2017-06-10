require 'active_support/concern'

module Concerns
  module Person
    module Relationships
      extend ActiveSupport::Concern

      included do
        has_many :relationships, dependent: :delete_all, inverse_of: :person
        has_many :related_people, class_name: 'Person', through: :relationships, source: :related
        has_many :inward_relationships, class_name: 'Relationship', foreign_key: 'related_id', dependent: :delete_all
        has_many :inward_related_people, class_name: 'Person', through: :inward_relationships, source: :person
        accepts_nested_attributes_for :relationships, allow_destroy: true
      end

      def update_relationships_hash
        rels = relationships.includes(:related).to_a.reject do |relationship|
          Setting.get(:system, :online_only_relationships).include?(relationship.name_or_other)
        end.map do |relationship|
          "#{relationship.related.legacy_id}[#{relationship.name_or_other}]"
        end.sort
        self.relationships_hash = Digest::SHA1.hexdigest(rels.join(','))
      end

      def update_relationships_hash!
        update_relationships_hash
        save(validate: false)
      end

      def relationships=(r)
        case r
        when nil, String
          self.relationships_from_string = r.to_s
        else
          super
        end
      end

      # TODO: apply relationships *after* a CSV import is complete so that all the legacy_ids exist
      def relationships_from_string=(string)
        existing = relationships.to_a
        new_and_existing = string.scan(/(\d+)\[([^\]]+)\]/).map do |related_id, name|
          if I18n.t(name.downcase, scope: 'relationships.names', default: '').present?
            other_name = nil
            name = name.downcase
          else
            other_name = name
            name = 'other'
          end
          next unless (related = self.class.where(legacy_id: related_id).first)
          if (record = existing.detect { |r| [r.related_id, r.name, r.other_name] == [related.id, name, other_name] })
            { id: record.id }
          else
            { name: name, other_name: other_name, person_id: id, related_id: related.id }
          end
        end.compact
        keep_ids = new_and_existing.map { |r| r[:id] }.compact
        old = existing.reject { |r| keep_ids.include?(r.id) }.map do |record|
          { id: record.id, _destroy: true }
        end
        self.relationships_attributes = new_and_existing + old
      end
    end
  end
end
