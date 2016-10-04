require 'active_support/concern'

module Concerns
  module Person
    module Fields
      extend ActiveSupport::Concern

      included do
        has_many :custom_field_values, as: :object, inverse_of: :object, autosave: true
      end

      def fields
        field_ids = CustomField.pluck(:id)
        custom_field_values.each_with_object({}) do |field_value, hash|
          hash[field_value.field_id] = field_value.value if field_ids.include?(field_value.field_id)
        end
      end

      def fields=(attrs)
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
    end
  end
end
