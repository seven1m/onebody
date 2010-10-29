require 'active_record'

module Foo
  module Acts #:nodoc:
    module LoggerPlugin #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_logger(log_class, options={})
          class_eval <<-END
            @@log_class = #{log_class.name}
            @@log_ignore_attributes = #{options[:ignore].to_a.inspect} + %w(updated_at created_at)
            before_save :get_changes
            after_save :log_changes
            after_destroy :log_destroy

            def get_changes
              @logger_changes = self.changes.to_hash.reject { |k, v| @@log_ignore_attributes.include?(k) }
            end

            def log_changes
              if @logger_changes.any? and @@log_class.table_exists? \
                and @@log_class.column_names.include?('loggable_id')
                @@log_class.create(
                  :name => self.respond_to?(:name) ? self.name : nil,
                  :loggable_type => self.class.name,
                  :loggable_id => self.id,
                  :object_changes => @logger_changes,
                  :person => Person.logged_in,
                  :group_id => self.respond_to?(:group_id) ? self.group_id : nil
                )
              end
            end

            def log_destroy
              if @@log_class.table_exists? \
                and @@log_class.column_names.include?('loggable_id')
                @@log_class.create(
                  :name => self.respond_to?(:name) ? self.name : nil,
                  :loggable_type => self.class.name,
                  :loggable_id => self.id,
                  :deleted => true,
                  :person => Person.logged_in,
                  :group_id => self.respond_to?(:group_id) ? self.group_id : nil
                )
                @@log_class.find_all_by_loggable_type_and_loggable_id(
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
