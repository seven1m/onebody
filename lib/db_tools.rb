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
  def values_hash(*attrs)
    attrs = attrs.first if attrs.first.is_a?(Array)
    values = attrs.map do |attr|
      value = read_attribute(attr)
      value.respond_to?(:strftime) ? value.strftime('%Y/%m/%d %H:%M') : value
    end
    Digest::SHA1.hexdigest(values.join)
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
