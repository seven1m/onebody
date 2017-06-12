require 'active_model'

module ActiveModel::Validations::HelperMethods
  def blank_to_nil(*attrs)
    before_validation do |record|
      attrs.each do |attr|
        value = send(attr)
        if value.respond_to?(:blank?)
          record[attr] = nil if value.blank?
        end
      end
    end
  end
end
