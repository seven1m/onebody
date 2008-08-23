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
      value = attributes[attr.to_s]
      value.respond_to?(:strftime) ? value.strftime('%Y%m%d%H%M') : value
    end
    Digest::SHA1.hexdigest(values.to_s)
  end
end