#
# The ArrayFields module implements methods which allow an Array to be indexed
# by String or Symbol. It is not required to manually use this module to
# extend Arrays - they are auto-extended on a per-object basis when
# Array#fields= is called
#
  module ArrayFields 
    self::VERSION = '4.5.0' unless defined? self::VERSION
    def self.version() VERSION end
  #
  # multiton cache of fields - wraps fields and fieldpos map to save memory
  #
    class FieldSet
      class << self
        def new fields
          @sets[fields] ||= super
        end
        def init_sets
          @sets = {}
        end
      end

      init_sets

      attr :fields
      attr :fieldpos
      def initialize fields
        raise ArgumentError, "<#{ fields.inspect }> not inject-able" unless
          fields.respond_to? :inject

        @fieldpos =
          fields.inject({}) do |h, f|
            unless String === f or Symbol === f
              raise ArgumentError, "<#{ f.inspect }> neither String nor Symbol"
            end
            h[f] = h.size
            h
          end

        @fields = fields
      end
      def pos f
        return @fieldpos[f] if @fieldpos.has_key? f 
        f = f.to_s
        return @fieldpos[f] if @fieldpos.has_key? f 
        f = f.intern
        return @fieldpos[f] if @fieldpos.has_key? f 
        nil
      end
    end
  #
  # methods redefined to work with fields as well as numeric indexes
  #
    def [] idx, *args
      if @fieldset and (String === idx or Symbol === idx)
        pos = @fieldset.pos idx
        return nil unless pos
        super(pos, *args)
      else
        super
      end
    end
    def slice idx, *args
      if @fieldset and (String === idx or Symbol === idx)
        pos = @fieldset.pos idx
        return nil unless pos
        super(pos, *args)
      else
        super
      end
    end

    def []=(idx, *args) 
      if @fieldset and (String === idx or Symbol === idx) 
        pos = @fieldset.pos idx
        unless pos
          @fieldset.fields << idx
          @fieldset.fieldpos[idx] = pos = size
        end
        super(pos, *args)
      else
        super
      end
    end
    def at idx
      if @fieldset and (String === idx or Symbol === idx)
        pos = @fieldset.pos idx
        return nil unless pos
        super pos
      else
        super
      end
    end
    def delete_at idx
      if @fieldset and (String === idx or Symbol === idx)
        pos = @fieldset.pos idx
        return nil unless pos
        super pos
      else
        super
      end
    end
    def fill(obj, *args)
      idx = args.first
      if idx and @fieldset and (String === idx or Symbol === idx)
        idx = args.shift
        pos = @fieldset.pos idx
        super(obj, pos, *args)
      else
        super
      end
    end

    def values_at(*idxs)
      idxs.flatten!
      if @fieldset
        idxs.map!{|i| (String === i or Symbol === i) ? @fieldset.pos(i) : i}
      end
      super(*idxs)
    end
    def indices(*idxs)
      idxs.flatten!
      if @fieldset
        idxs.map!{|i| (String === i or Symbol === i) ? @fieldset.pos(i) : i}
      end
      super(*idxs)
    end
    def indexes(*idxs)
      idxs.flatten!
      if @fieldset
        idxs.map!{|i| (String === i or Symbol === i) ? @fieldset.pos(i) : i}
      end
      super(*idxs)
    end

    def slice!(*args)
      ret = self[*args]
      self[*args] = nil
      ret
    end
    def each_with_field
      each_with_index do |elem, i|
        yield elem, @fieldset.fields[i]
      end
    end
  #
  # methods which give a hash-like interface 
  #
    def each_pair
      each_with_index do |elem, i|
        yield @fieldset.fields[i], elem
      end
    end
    def each_key
      @fieldset.each{|field| yield field}
    end
    def each_value *args, &block
      each *args, &block
    end
    def fetch key
      self[key] or raise IndexError, 'key not found'
    end

    def has_key? key
      @fieldset.fields.include? key
    end
    def member? key
      @fieldset.fields.include? key
    end
    def key? key
      @fieldset.fields.include? key
    end

    def has_value? value
      if respond_to? 'include?'
        self.include? value
      else
        a = []
        each{|val| a << val}
        a.include? value
      end
    end
    def value? value
      if respond_to? 'include?'
        self.include? value
      else
        a = []
        each{|val| a << val}
        a.include? value
      end
    end

    def keys
      fields
    end
    def store key, value
      self[key] = value
    end
    def values
      if respond_to? 'to_ary'
        self.to_ary
      else
        a = []
        each{|val| a << val}
        a
      end
    end

    def to_hash
      if respond_to? 'to_ary'
        h = {}
        @fieldset.fields.zip(to_ary){|f,e| h[f] = e}
        h
      else
        a = []
        each{|val| a << val}
        h = {}
        @fieldset.fields.zip(a){|f,e| h[f] = e}
        h
      end
    end
    def to_h
      if respond_to? 'to_ary'
        h = {}
        @fieldset.fields.zip(to_ary){|f,e| h[f] = e}
        h
      else
        a = []
        each{|val| a << val}
        h = {}
        @fieldset.fields.zip(a){|f,e| h[f] = e}
        h
      end
    end

    def update other
      other.each{|k,v| self[k] = v}
      to_hash
    end
    def replace other
      Hash === other ? update(other) : super
    end
    def invert
      to_hash.invert
    end

    def to_pairs
      fields.zip values
    end
    alias_method 'pairs', 'to_pairs'

    def copy 
      cp = clone
      cp.fields = fields.clone
      cp 
    end

    alias_method 'dup', 'copy'
    alias_method 'clone', 'copy'

    def deepcopy 
      cp = Marshal.load(Marshal.dump(self))
      cp.fields = Marshal.load(Marshal.dump(self.fields))
      cp 
    end
  end
  Arrayfields = ArrayFields

  module Arrayfields
    def self.new *pairs
      pairs = pairs.map{|pair| Enumerable === pair ? pair.to_a : pair}.flatten
      raise ArgumentError, "pairs must be evenly sized" unless(pairs.size % 2 == 0)
      (( array = [] )).fields = []
      0.step(pairs.size - 2, 2) do |a|
        b = a + 1
        array[ pairs[a] ] = pairs[b]
      end
      array
    end
    def self.[] *pairs
      new *pairs
    end
  end
  def Arrayfields(*a, &b) Arrayfields.new(*a, &b) end
#
# Fieldable encapsulates methods in common for classes which may have their
# fields set and subsequently be auto-extended by ArrayFields
#
  module Fieldable
  #
  # sets fields an dynamically extends this Array instance with methods for
  # keyword access
  #
    def fields= fields
      extend ArrayFields unless ArrayFields === self

      @fieldset = 
        if ArrayFields::FieldSet === fields
          fields
        else
          ArrayFields::FieldSet.new fields
        end
    end
  #
  # access to fieldset
  #
    attr_reader :fieldset
  #
  # access to field list
  #
    def fields
      @fieldset and @fieldset.fields
    end
  end
#
# Array instances are extened with two methods only: Fieldable#fields= and
# Fieldable#fields.  only when Fieldable#fields= is called will the full set
# of ArrayFields methods auto-extend the Array instance.  the Array class also
# has added a class generator when the fields are known apriori.
#
  class Array
    include Fieldable

    class << self
      def struct *fields
        fields = fields.flatten
        Class.new(self) do
          include ArrayFields
          const_set :FIELDS, ArrayFields::FieldSet.new(fields)
          fields.each do |field|
            field = field.to_s
            if field =~ %r/^[a-zA-Z_][a-zA-Z0-9_]*$/
              begin
                module_eval <<-code
                  def #{ field } *a
                    a.size == 0 ? self['#{ field }'] : (self.#{ field } = a.shift) 
                  end
                  def #{ field }= value
                    self['#{ field }'] = value
                  end
                code
              rescue SyntaxError
                :by_ignoring_it
              end
            end
          end
          def initialize *a, &b
            super
          ensure
            @fieldset = self.class.const_get :FIELDS
          end
          def self.[] *elements
            array = new
            array.replace elements
            array
          end
        end
      end
      def fields *fields, &block
        (( array = new(&block) )).fields = fields.map{|x| Enumerable === x ? x.to_a : x}.flatten
        array
      end
    end
  end
#
# proxy class that allows an array to be wrapped in a way that still allows #
# keyword access.  also facilitate usage of ArrayFields with arraylike objects.
# thnx to Sean O'Dell for the suggestion.
#
# sample usage
#
# fa = FieldedArray.new %w(zero one two), [0,1,2]
# p fa['zero']   #=> 0
#
#
  class FieldedArray
    include Fieldable
    class << self
      def [](*pairs)
        pairs.flatten!
        raise ArgumentError, "argument must be key/val pairs" unless 
          (pairs.size % 2 == 0)
        fields, elements = [], []
        while((f = pairs.shift) and (e = pairs.shift)) 
          fields << f and elements << e
        end
        new fields, elements
      end
    end
    def initialize fields = [], array = []
      @a = array
      self.fields = fields
    end
    def method_missing(meth, *args, &block)
      @a.send(meth, *args, &block)
    end
    delegates =
      %w(
        to_s
        to_str
        inspect
      )
    delegates.each do |meth| 
      class_eval "def #{ meth }(*a,&b); @a.#{ meth }(*a,&b);end"
    end
  end
  Fieldedarray = FieldedArray

  class PseudoHash < ::Array
    class << self
      def [](*pairs)
        pairs.flatten!
        raise ArgumentError, "argument must be key/val pairs" unless 
          (pairs.size % 2 == 0 and pairs.size >= 2)
        keys, values = [], []
        while((k = pairs.shift) and (v = pairs.shift)) 
          keys << k and values << v
        end
        new keys, values
      end
    end
    def initialize keys = [], values = []
      self.fields = keys
      self.replace values
    end
    def to_yaml opts = {}
      YAML::quick_emit object_id, opts do |out|
        out.map taguri, to_yaml_style do |map|
          each_pair{|f,v| map.add f,v}
        end
      end
   end 
  end
  Pseudohash = PseudoHash
