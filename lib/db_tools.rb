def sql_concat(*args)
  SQLITE ? args.join(' || ') : "CONCAT(#{args.join(', ')})"
end

def sql_lcase(expr)
  SQLITE ? "LOWER(#{expr})" : "LCASE(#{expr})"
end

def sql_year(expr)
  SQLITE ? "CAST(STRFTIME('%y', #{expr}) as 'INTEGER')" : "YEAR(#{expr})"
end

def sql_month(expr)
  SQLITE ? "CAST(STRFTIME('%m', #{expr}) as 'INTEGER')" : "MONTH(#{expr})"
end

def sql_day(expr)
  SQLITE ? "CAST(STRFTIME('%d', #{expr}) as 'INTEGER')" : "DAY(#{expr})"
end

def sql_now
  SQLITE ? "CURRENT_TIMESTAMP" : "NOW()"
end

def sql_random
  SQLITE ? "RANDOM()" : "RAND()"
end

class ActiveRecord::Base
  def self.hashify(options)
    return [] unless connection.adapter_name == 'MySQL'
    attributes = options[:attributes].select { |a| column_names.include?(a.to_s) }.map { |a| "IFNULL(#{a}, '')" }.join(',')
    conditions = []
    conditions << "id in (#{options[:ids].to_a.map { |id| id.to_i }.join(',')})" if options[:ids].to_a.any?
    conditions << "legacy_id in (#{options[:legacy_ids].map { |id| id.to_i }.join(',')})" if options[:legacy_ids].to_a.any?
    connection.select_all("select id, legacy_id, #{attributes[:debug] ? '' : 'SHA1'}(CONCAT(#{attributes})) as hash from `#{table_name}` where #{conditions.join(' or ')} and site_id=#{Site.current.id} limit #{MAX_RECORD_HASHES}")
  end
end

# add option to to_xml to specify that read_attribute() should be used rather than send()
# for grabbing attribute values
module ActiveRecord
  class XmlSerializer

    def serializable_attributes_with_read_attribute_option
      if options[:read_attribute]
        serializable_attribute_names.collect { |name| DataOnlyAttribute.new(name, @record) }
      else
        serializable_attributes_without_read_attribute_option
      end
    end
    alias_method_chain :serializable_attributes, :read_attribute_option

    class DataOnlyAttribute < Attribute
      protected
        def compute_value
          value = @record.read_attribute(name)

          if formatter = Hash::XML_FORMATTING[type.to_s]
            value ? formatter.call(value) : nil
          else
            value
          end
        end
    end
  end
end
