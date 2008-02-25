module ActiveRecord
  class Base
    def update_attributes_if_changed(attr)
      attr.delete_if { |a, v| v == self.attributes[a.to_s] }
      update_attributes(attr) if attr.any?
    end
    def update_attributes_if_changed!(attr)
      attr.delete_if { |a, v| v == self.attributes[a.to_s] }
      update_attributes!(attr) if attr.any?
    end
  end
end