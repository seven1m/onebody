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

  def self.scope_by_site_id
    #acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 0)"
    default_scope lambda { where(:site_id => Site.current.id) }
  end

  def self.hashify(options)
    return [] unless connection.adapter_name == 'MySQL'
    attributes = options[:attributes].select { |a| column_names.include?(a.to_s) }.map { |a| "IFNULL(#{a}, '')" }.join(',')
    conditions = []
    conditions << "id in (#{options[:ids].to_a.map { |id| id.to_i }.join(',')})" if options[:ids].to_a.any?
    conditions << "legacy_id in (#{options[:legacy_ids].map { |id| id.to_i }.join(',')})" if options[:legacy_ids].to_a.any?
    connection.select_all("select id, legacy_id, #{table_name =~ /people/ ? 'family_id,' : nil} #{options[:debug] ? '' : 'SHA1'}(CONCAT(#{attributes})) as hash from `#{table_name}` where #{conditions.join(' or ')} and site_id=#{Site.current.id} limit #{MAX_RECORD_HASHES}")
  end

  def self.digits_only_for_attributes=(attributes)
    attributes.each do |attribute|
      class_eval "
        def #{attribute}=(val)
          write_attribute :#{attribute}, val.to_s.digits_only
        end
      "
    end
  end

  def self.fall_through_attributes(*attributes)
    options = attributes.pop.symbolize_keys
    attributes.each do |attribute|
      class_eval "
        def #{attribute}; #{options[:to]} && #{options[:to]}.#{attribute}; end
      "
    end
  end


  def to_mongo_hash
    attributes.inject({}) do |hash, item|
      key, value = item
      if value.is_a?(Time) or value.is_a?(DateTime)
        value = value.utc.strftime('%Y-%m-%dT%H:%M:%S%z')
      end
      hash.update(key => value)
    end
  end
end
