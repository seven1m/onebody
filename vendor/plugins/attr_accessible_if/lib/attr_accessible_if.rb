module ActiveRecord #:nodoc:
  class Base
    
    class << self
      def attr_accessible(*attributes)
        if attributes.last.is_a?(Hash)
          options = attributes.pop
          options.symbolize_keys!
        else
          options = {}
        end
        attributes = (read_inheritable_attribute(:attr_accessible) || {}).merge(
          attributes.inject({}) do |hash, attribute|
            hash[attribute.to_s] = options
            hash
          end
        )
        write_inheritable_attribute(:attr_accessible, attributes)
      end
      
      def accessible_attributes # :nodoc:
        if attributes = read_inheritable_attribute(:attr_accessible)
          attributes.select do |attribute, options|
            (options[:if] and options[:if].call) or !options[:if]
          end.map { |a, o| a }
        end
      end
      
    end
  end
end
