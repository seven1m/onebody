class Mode < ::String
  class Error < ::StandardError; end
  class Duplicate < Error; end
  class Ambiguous < Error
    include Main::Softspoken
  end

  class List < ::Array
    def initialize *a, &b
      super
    ensure
      self.fields = []
    end
    def add klass
      mode_name = Mode.new klass.mode_name
      raise Duplicate, mode_name if has_key? mode_name
      self[mode_name] = klass
    end
    def find_by_mode m, options = {}
      quiet = options['quiet'] || options[:quiet]
      each_pair do |mode, klass|
        return mode if mode == m
      end
      candidates = []
      each_pair do |mode, klass|
        candidates << mode if mode.index(m) == 0
      end
      case candidates.size
        when 0
          nil
        when 1
          candidates.first
        else
          raise Ambiguous, "ambiguous mode: #{ m } = (#{ candidates.sort.join ' or ' })?"
      end
    end
  end

  def self.list *a, &b
    List.new *a, &b
  end
end
