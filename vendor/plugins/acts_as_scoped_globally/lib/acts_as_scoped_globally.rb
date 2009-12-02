require 'active_record'

module Seven1m
  module ActsAsScopedGlobaly

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_scoped_globally(foreign_key, value)
        class_eval <<-END
          attr_protected '#{foreign_key}'
          
          class << self
            def find_by_sql_with_global_scope(sql) 
              unless disable_global_scope
                sql = sanitize_sql(sql)
                unless sql.index('#{foreign_key} =') # already present (probably from current_scoped_methods)
                  unless sql.gsub!(/from\\s+(["`]?[a-z_]+["`]?)\\s+((inner|left\\s+outer)\\s+join\\s+.+)?where/i, "\\\\0 \\\\1.#{foreign_key} = " + #{value}.to_s + " and") or 
                    sql.gsub!(/from\\s+(["`]?[a-z_]+["`]?)\\s+((inner|left\\s+outer)\\s+join\\s+.+)?/i, "\\\\0where \\\\1.#{foreign_key} = " + #{value}.to_s + ' ') 
                    raise "Error inserting site selection condition in sql: " + sql
                  end
                end
              end
              find_by_sql_without_global_scope(sql)
            end
            alias_method_chain(:find_by_sql, :global_scope) unless instance_methods.include?('find_by_sql_without_global_scope')
            
            def current_scoped_methods_with_global_scope
              m = current_scoped_methods_without_global_scope || {}
              unless disable_global_scope
                m[:find] ||= {}
                m[:find][:conditions] ||= ''
                unless m[:find][:conditions].index('#{foreign_key} =') or
                  m[:find][:conditions].gsub! /(#{foreign_key} = )\d+/, '\\1' + #{value}.to_s
                  if m[:find][:conditions].to_s != ''
                    m[:find][:conditions] += ' and'
                  end
                  m[:find][:conditions] += ' `#{table_name}`.#{foreign_key} = ' + #{value}.to_s
                end
              end
              return m
            end
            alias_method_chain(:current_scoped_methods, :global_scope) unless instance_methods.include?('current_scoped_methods_without_global_scope')
            
            def without_global_scope
              self.disable_global_scope = true
              yield
              self.disable_global_scope = nil
            end
            
            attr_accessor :disable_global_scope
          end

          def create_with_global_scope
            unless self.class.disable_global_scope
              self.#{foreign_key} ||= #{value}
            end
            create_without_global_scope
          end
          alias_method_chain(:create, :global_scope) unless instance_methods.include?('create_without_global_scope')
        END
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Seven1m::ActsAsScopedGlobaly
end
