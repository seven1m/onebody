require 'active_support/concern'

module Concerns
  module Import
    module Attributes
      extend ActiveSupport::Concern

      def attributes_for_person(row)
        attributes(row).select { |a| a !~ /^family_/ }
      end

      def attributes_for_family(row)
        family_attributes = attributes(row).select { |a| a =~ /^family_/ }
        family_attributes.each_with_object({}) do |(name, value), hash|
          hash[name.sub(/^family_/, '')] = value
        end
      end

      def attributes(row)
        row.import_attributes_as_hash(real_attributes: true)
      end

      def errors_as_string(person)
        family_errors = person.errors.delete(:family)
        errors = person.errors.values
        errors += person.family.errors.values if family_errors
        errors.join('; ')[0...255].presence
      end
    end
  end
end

