class ActiveRecord::Base

  def self.scope_by_site_id
    default_scope lambda { where(site_id: Site.current.id) }
  end

  def self.hashify(options)
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

end
