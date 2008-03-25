require 'active_record'

module Foo
  module Acts #:nodoc:
    module ScopedGlobaly #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_scoped_globally(foreign_key, value)
          class_eval <<-END
            attr_protected '#{foreign_key}'
            
            class << self
              alias_method :rails_original_find_by_sql, :find_by_sql 
              def find_by_sql(sql) 
                sql = sanitize_sql(sql)
                unless sql.index('#{foreign_key} =') # already present (probably from current_scoped_methods)
                  unless sql.gsub!(/from\\s+(["`]?[a-z_]+["`]?)\\s+((inner|left\\s+outer)\\s+join\\s+.+)?where/i, "\\\\0 \\\\1.#{foreign_key} = " + #{value}.to_s + " and") or 
                    sql.gsub!(/from\\s+(["`]?[a-z_]+["`]?)\\s+((inner|left\\s+outer)\\s+join\\s+.+)?/i, "\\\\0where \\\\1.#{foreign_key} = " + #{value}.to_s + ' ') 
                    raise "Error inserting site selection condition in sql: " + sql
                  end
                end
	              rails_original_find_by_sql(sql)
	            end
              
              alias_method :rails_original_current_scoped_methods, :current_scoped_methods
              def current_scoped_methods
                m = rails_original_current_scoped_methods || {}
                m[:find] ||= {}
                m[:find][:conditions] ||= ''
                unless m[:find][:conditions].index('#{foreign_key} =') or
                  m[:find][:conditions].gsub! /(#{foreign_key} = )\d+/, '\\1' + #{value}.to_s
                  if m[:find][:conditions].any?
                    m[:find][:conditions] += ' and'
                  end
                  m[:find][:conditions] += ' `#{table_name}`.#{foreign_key} = ' + #{value}.to_s
                end
                return m
              end
            end

            alias_method :rails_original_create, :create
            def create
              self.#{foreign_key} ||= #{value}
              rails_original_create
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
  include Foo::Acts::ScopedGlobaly
end