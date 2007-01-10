require 'active_record'

module Foo
  module Acts #:nodoc:
    module LoggerPlugin #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_logger(log_class)
          class_eval <<-END
            @@log_class = #{log_class.name}
            before_save :compare_changes
            after_save :log_changes
            
            def compare_changes
              if new_record?
                @changes = attributes
              else
                original = self.class.find(id)
                @changes = original.attributes.compare_with(attributes)
              end
            end
            
            def log_changes
              @changes.delete 'updated_at'
              @changes.delete 'created_at'
              if @changes.any?
                @@log_class.create(
                  :model_name => self.class.name,
                  :instance_id => self.id,
                  :changes => @changes
                )
              end
            end
          END
        end
      end

    end
  end
end

class Hash
  def compare_with(hash)
    different = {}
    hash.each do |key, value|
      different[key] = value if self[key] != value
    end
    return different
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include Foo::Acts::LoggerPlugin
end
