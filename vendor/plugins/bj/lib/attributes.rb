module Attributes
  Attributes::VERSION = '5.0.0' unless defined? Attributes::VERSION
  def self.version() Attributes::VERSION end

  class List < ::Array
    def << element
      super
      self
    ensure
      uniq!
      index!
    end
    def index!
      @index ||= Hash.new
      each{|element| @index[element] = true}
    end
    def include? element
      @index ||= Hash.new
      @index[element] ? true : false
    end
    def initializers
      @initializers ||= Hash.new
    end
  end

  def attributes *a, &b
    unless a.empty?
      returned = Hash.new

      hashes, names = a.partition{|x| Hash === x}
      names_and_defaults = {}
      hashes.each{|h| names_and_defaults.update h}
      names.flatten.compact.each{|name| names_and_defaults.update name => nil}

      initializers = __attributes__.initializers

      names_and_defaults.each do |name, default|
        raise NameError, "bad instance variable name '@#{ name }'" if "@#{ name }" =~ %r/[!?=]$/o
        name = name.to_s

        initialize = b || lambda { default }
        initializer = lambda do |this|
          Object.instance_method('instance_eval').bind(this).call &initialize
        end
        initializer_id = initializer.object_id
        __attributes__.initializers[name] = initializer

        module_eval <<-code
          def #{ name }=(*value, &block)
            value.unshift block if block
            @#{ name } = value.first
          end
        code

        module_eval <<-code
          def #{ name }(*value, &block)
            value.unshift block if block
            return self.send('#{ name }=', value.first) unless value.empty?
            #{ name }! unless defined? @#{ name }
            @#{ name }
          end
        code

        module_eval <<-code
          def #{ name }!
            initializer = ObjectSpace._id2ref #{ initializer_id }
            self.#{ name } = initializer.call(self)
            @#{ name }
          end
        code

        module_eval <<-code
          def #{ name }?
            #{ name }
          end
        code

        attributes << name
        returned[name] = initializer 
      end

      returned
    else
      begin
        __attribute_list__
      rescue NameError
        singleton_class =
          class << self
            self
          end
        klass = self
        singleton_class.module_eval do
          attribute_list = List.new 
          define_method('attribute_list'){ klass == self ? attribute_list : raise(NameError) }
          alias_method '__attribute_list__', 'attribute_list'
        end
        __attribute_list__
      end
    end
  end

  %w( __attributes__ __attribute__ attribute ).each{|dst| alias_method dst, 'attributes'}
end

class Object
  def attributes *a, &b
    sc = 
      class << self
        self
      end
    sc.attributes *a, &b
  end
  %w( __attributes__ __attribute__ attribute ).each{|dst| alias_method dst, 'attributes'}
end

class Module
  include Attributes
end
