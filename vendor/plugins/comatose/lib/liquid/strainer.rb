module Liquid

  # Strainer is the parent class for the filters system. 
  # New filters are mixed into the strainer class which is then instanciated for each liquid template render run. 
  #
  # One of the strainer's responsibilities is to keep malicious method calls out 
  class Strainer
    @@required_methods = ["__send__", "__id__", "respond_to?", "extend", "methods"]
    
    @@filters = []
    
    def initialize(context)
      @context = context
    end
              
    def self.global_filter(filter)
      raise StandardError, "Passed filter is not a module" unless filter.is_a?(Module)      
      @@filters << filter
    end
    
    def self.create(context)
      strainer = Strainer.new(context)
      @@filters.each { |m| strainer.extend(m) }
      strainer
    end
    
    def respond_to?(method)
      method_name = method.to_s
      return false if method_name =~ /^__/ 
      return false if @@required_methods.include?(method_name)
      super
    end
    
    # remove all standard methods from the bucket so circumvent security 
    # problems 
    instance_methods.each do |m| 
      unless @@required_methods.include?(m) 
        undef_method m 
      end
    end    
  end
end