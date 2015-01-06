require 'active_support/concern'

module Concerns
  module Person
    module Relationships
      extend ActiveSupport::Concern

      included do
        has_many :relationships, dependent: :delete_all
        has_many :related_people, class_name: 'Person', through: :relationships, source: :related
        has_many :inward_relationships, class_name: 'Relationship', foreign_key: 'related_id', dependent: :delete_all
        has_many :inward_related_people, class_name: 'Person', through: :inward_relationships, source: :person
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
    end
  end
end
