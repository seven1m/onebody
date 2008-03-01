class Hash
  begin
    method "to_options"
  rescue
    def to_options
      inject(Hash.new){|h, kv| h.update kv.first.to_s.to_sym => kv.last}
    end
    def to_options!
      replace to_options
    end
  end

  begin
    method "to_string_options"
  rescue
    def to_string_options
      inject(Hash.new){|h, kv| h.update kv.first.to_s => kv.last}
    end
    def to_string_options!
      replace to_string_options
    end
  end

  begin
    method "reverse_merge"
  rescue
    def reverse_merge other
      other.merge self
    end
    def reverse_merge! other
      replace reverse_merge(other)
    end
  end

  begin
    method "slice"
  rescue
    def slice(*keys)
      allowed = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
      reject { |key,| !allowed.include?(key) }
    end
  end

  begin
    method "slice!"
  rescue
    def slice!(*keys)
      replace(slice(*keys))
    end
  end
end

class Object
  begin
    method "returning"
  rescue
    def returning value, &block
      block.call value
      value
    end
  end
end

class Object
  def singleton_class &block
    @singleton_class ||=
      class << self
        self
      end
    block ? @singleton_class.module_eval(&block) : @singleton_class
  end
end

class String
  begin
    method 'underscore'
  rescue
    def underscore
      gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end
end
