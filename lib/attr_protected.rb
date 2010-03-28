module ActiveRecord #:nodoc:
  class Base
    class << self
      def attr_protected_with_reset(*attributes)
        if attributes.length == 1 and attributes.first.nil?
          write_inheritable_attribute(:attr_protected, nil)
        else
          attr_protected_without_reset(*attributes)
        end
      end
      alias_method_chain :attr_protected, :reset
    end
  end
end
