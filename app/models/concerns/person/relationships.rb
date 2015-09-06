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
        accepts_nested_attributes_for :relationships
      end

      def update_relationships_hash
        rels = relationships.includes(:related).to_a.select do |relationship|
          !Setting.get(:system, :online_only_relationships).include?(relationship.name_or_other)
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

      def relationships_from_string=(string)
        self.relationships_attributes = string.scan(/(\d+)\[([^\]]+)\]/).map do |related_id, name|
          if I18n.t(name.downcase, scope: 'relationships.names', default: '').present?
            other_name = nil
            name = name.downcase
          else
            other_name = name
            name = 'other'
          end
          related = self.class.where(legacy_id: related_id).first
          { name: name, other_name: other_name, person_id: id, related_id: related.try(:id) }
        end
      end
    end
  end
end
