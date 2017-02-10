require 'active_support/concern'

module Concerns
  module Person
    module Fields
      extend ActiveSupport::Concern

      included do
        has_many :custom_field_values, as: :object, inverse_of: :object, autosave: true
      end

      def fields
        @fields ||= begin
          field_ids = CustomField.pluck(:id)
          custom_field_values.each_with_object({}) do |field_value, hash|
            hash[field_value.field_id] = field_value.value if field_ids.include?(field_value.field_id)
          end
        end
      end

      def fields=(attrs)
        @fields_before = fields
        attrs = attrs.stringify_keys
        custom_field_values.each do |field_value|
          if (value = attrs.delete(field_value.field_id.to_s))
            field_value.value = value
          end
        end
        attrs.each do |field_id, value|
          custom_field_values.build(field_id: field_id, value: value)
        end
      end

      def reload
        @fields = nil
        @fields_before = nil
        super
      end

      def field_changes
        @fields = nil
        @fields_before ||= fields
        changes = {}
        @fields_before.each do |id, old_value|
          new_value = fields[id]
          changes[id] = [old_value, new_value]
        end
        fields.each do |id, new_value|
          changes[id] ||= [nil, new_value]
        end
        changes.reject do |_id, (old_value, new_value)|
          old_value == new_value
        end
      end

      def fields_changed?
        field_changes.any?
      end
    end
  end
end
