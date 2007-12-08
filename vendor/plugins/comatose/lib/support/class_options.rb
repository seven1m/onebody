class Class
  def define_option(name, default=nil)
    sym = name.to_sym
    cattr_reader(sym)
    cattr_writer(sym)
    send("#{name.to_s}=", default)
  end
  
  def blockable_attr_accessor(sym)
    module_eval(<<-EVAL, __FILE__, __LINE__)
      def #{sym}(&block)
        if block_given?
          @#{sym} = block
        else
          @#{sym}
        end
      end
      def #{sym}=(value)
        @#{sym} = value
      end
    EVAL
  end
end

class Module
  def attr_accessor_with_default(sym, default = nil, &block)
    raise 'Default value or block required' unless !default.nil? || block
    define_method(sym, block_given? ? block : Proc.new { default })
    module_eval(<<-EVAL, __FILE__, __LINE__)
      def #{sym}=(value)
        class << self; attr_reader :#{sym} end
        @#{sym} = value
      end
    EVAL
  end
end
