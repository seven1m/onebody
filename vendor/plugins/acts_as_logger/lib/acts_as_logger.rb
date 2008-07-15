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
            before_save :get_changes
            after_save :log_changes
            after_destroy :log_destroy
            
            def get_changes
              @logger_changes = self.changes.reject { |k, v| %w(updated_at created_at).include? k }
            end
            
            def log_changes
              if @logger_changes.any? and @@log_class.table_exists?
                @@log_class.create(
                  :name => self.respond_to?(:name) ? self.name : nil,
                  :model_name => self.class.name,
                  :instance_id => self.id,
                  :changes => @logger_changes,
                  :person => Person.logged_in,
                  :group_id => self.respond_to?(:group_id) ? self.group_id : nil
                )
              end
            end
            
            def log_destroy
              if @@log_class.table_exists?
                @@log_class.create(
                  :name => self.respond_to?(:name) ? self.name : nil,
                  :model_name => self.class.name,
                  :instance_id => self.id,
                  :deleted => true,
                  :person => Person.logged_in,
                  :group_id => self.respond_to?(:group_id) ? self.group_id : nil
                )
                @@log_class.find_all_by_model_name_and_instance_id(
                  self.class.name,
                  self.id
                ).each { |l| l.update_attribute :deleted, true }
              end
            end
          END
        end
      end

    end
  end
end


# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include Foo::Acts::LoggerPlugin
end
