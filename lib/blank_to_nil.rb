require "active_model"

module ActiveModel::Validations::HelperMethods
  def blank_to_nil(*attrs)
    before_validation do |record|
      record.attributes.each do |attr, value|
        next unless attrs.include?(attr.to_sym)
        if value.respond_to?(:blank?)
          record[attr] = nil if value.blank?
        end
      end
    end
  end
end
