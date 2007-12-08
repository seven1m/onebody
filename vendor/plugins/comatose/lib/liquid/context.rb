module Liquid
  
  class ContextError < StandardError
  end
  
  # Context keeps the variable stack and resolves variables, as well as keywords
  #
  #   context['variable'] = 'testing'
  #   context['variable'] #=> 'testing'
  #   context['true']     #=> true
  #   context['10.2232']  #=> 10.2232
  #   
  #   context.stack do 
  #      context['bob'] = 'bobsen'
  #   end
  #
  #   context['bob']  #=> nil  class Context
  class Context
    attr_reader :assigns
    attr_accessor :registers
    
    def initialize(assigns = {}, registers = nil)
      @assigns = [assigns]
      @registers = registers || {}
    end
           
    def strainer
      @strainer ||= Strainer.create(self)
    end
               
    # adds filters to this context. 
    # this does not register the filters with the main Template object. see <tt>Template.register_filter</tt> 
    # for that
    def add_filters(filter)
      return unless filter.is_a?(Module)
      strainer.extend(filter)
    end
                              
    def invoke(method, *args)
      if strainer.respond_to?(method)
        strainer.__send__(method, *args)
      else
        return args[0]
      end        
    end

    # push new local scope on the stack. use <tt>Context#stack</tt> instead
    def push
      @assigns.unshift({})
    end
    
    # merge a hash of variables in the current local scope
    def merge(new_assigns)
      @assigns[0].merge!(new_assigns)
    end
  
    # pop from the stack. use <tt>Context#stack</tt> instead
    def pop
      raise ContextError if @assigns.size == 1 
      @assigns.shift
    end
    
    # pushes a new local scope on the stack, pops it at the end of the block
    #
    # Example:
    #
    #   context.stack do 
    #      context['var'] = 'hi'
    #   end
    #   context['var]  #=> nil
    #
    def stack(&block)
      push
      begin
        result = yield
      ensure 
        pop
      end
      result      
    end
  
    # Only allow String, Numeric, Hash, Array or <tt>Liquid::Drop</tt>
    def []=(key, value)
      @assigns[0][key] = value
    end
  
    def [](key)
      resolve(key)
    end
  
    def has_key?(key)
      resolve(key) != nil
    end
        
    private
    
    # Look up variable, either resolve directly after considering the name. We can directly handle 
    # Strings, digits, floats and booleans (true,false). If no match is made we lookup the variable in the current scope and 
    # later move up to the parent blocks to see if we can resolve the variable somewhere up the tree.
    # Some special keywords return symbols. Those symbols are to be called on the rhs object in expressions
    #
    # Example: 
    #
    #   products == empty #=> products.empty?
    #
    def resolve(key)    
      case key
      when nil
        nil
      when 'true'
        true
      when 'false'
        false
      when 'empty'
        :empty?
      when 'nil', 'null'
        nil
      # Single quoted strings
      when /^'(.*)'$/
        $1.to_s
      # Double quoted strings
      when /^"(.*)"$/
        $1.to_s        
      # Integer and floats
      when /^(\d+)$/ 
        $1.to_i
      when /^(\d[\d\.]+)$/ 
        $1.to_f
      else
        variable(key)
      end
    end
    
    # fetches an object starting at the local scope and then moving up 
    # the hierachy 
    def fetch(key)
      begin
        for scope in @assigns
          if scope.has_key?(key)
            obj = scope[key]
            if obj.is_a?(Liquid::Drop)
              obj.context = self 
            end
            return obj
          end
        end
      rescue => e
        raise ContextError, "Could not fetch key #{key} from context: " + e.message
      end 
      nil
    end

    # resolves namespaced queries gracefully.
    # 
    # Example
    # 
    #  @context['hash'] = {"name" => 'tobi'}
    #  assert_equal 'tobi', @context['hash.name']
    def variable(key)                  
      parts = key.split(VariableAttributeSeparator)
      
      
      if object = fetch(parts.shift).to_liquid
        object.context = self if object.is_a?(Liquid::Drop)
        
        while not parts.size.zero?
          next_part_name = parts.shift
          
          # If the last part of the context variable is .size we just 
          # return the count of the objects in this object
          if next_part_name == 'size' and parts.empty?
            return object.size if object.is_a?(Array)
            return object.size if object.is_a?(Hash) && !object.has_key?(next_part_name)
          end
          
          return nil if not object.respond_to?(:has_key?)
          return nil if not object.has_key?(next_part_name)
          
          object = object[next_part_name].to_liquid
          object.context = self if object.is_a?(Liquid::Drop)
        end

        object
      else
        nil
      end
    end                                   
    
  end
end
