module ActiveRecord
  module Associations
    module ClassMethods
      def inherited_attribute(name, parent)
        @inherited_attributes ||= []
        @inherited_attributes << name
        name = name.to_s
        class_eval "def #{name}; (v = read_attribute(:#{name})).nil? ? (#{parent} && #{parent}.#{name}) : v; end"
        class_eval "alias_method :#{name}?, :#{name}"
      end

      def inherited_attributes(*attributes)
        options = attributes.pop.symbolize_keys
        attributes.each do |attribute|
          inherited_attribute(attribute, options[:parent])
        end
      end

      # generates a method like "share_mobile_phone_with(person)"
      def sharable_attribute(attribute)
        class_eval \
          "
          def share_#{attribute}_with(person)
            read_attribute(:visible) and
            (!respond_to?(:family_id) or
              (family and family.visible?)
            ) and (
              share_#{attribute}? or
              self == person or
              (self.respond_to?(:family_id) and self.family_id == person.family_id) or
              person.admin?(:view_hidden_properties) or
              share_#{attribute}_through_group_with(person)
            )
          end
          alias_method :share_#{attribute}_with?, :share_#{attribute}_with

          def share_#{attribute}_through_group_with(person)
            self.memberships.where(share_#{attribute}: true).any? do |m|
              person.member_of?(m.group)
            end
          end
          "
      end

      def sharable_attributes(*attributes)
        attributes.each do |attribute|
          sharable_attribute(attribute)
        end
      end
    end
  end
end
