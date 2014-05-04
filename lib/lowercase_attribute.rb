module LowercaseAttribute
  extend ActiveSupport::Concern

  module ClassMethods
    def lowercase_attribute(*attrs)
      attrs.each do |attr|
        class_eval <<-END
          def #{attr}=(e)
            e = e.downcase if e.present?
            super(e)
          end
        END
      end
    end
  end
end

ActiveRecord::Base.send(:include, LowercaseAttribute)
