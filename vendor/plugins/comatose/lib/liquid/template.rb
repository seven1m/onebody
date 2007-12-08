module Liquid

  # Templates are central to liquid. 
  # Interpretating templates is a two step process. First you compile the 
  # source code you got. During compile time some extensive error checking is performed. 
  # your code should expect to get some SyntaxErrors. 
  #
  # After you have a compiled template you can then <tt>render</tt> it. 
  # You can use a compiled template over and over again and keep it cached. 
  #
  # Example: 
  #   
  #   template = Liquid::Template.parse(source)
  #   template.render('user_name' => 'bob')
  #
  class Template
    attr_accessor :root
    @@file_system = BlankFileSystem.new
    
    def self.file_system
      @@file_system
    end
    
    def self.file_system=(obj)
      @@file_system = obj
    end
          
    def self.register_tag(name, klass)      
      tags[name.to_s] = klass
    end                        
    
    def self.tags
      @tags ||= {}
    end
        
    # Pass a module with filter methods which should be available 
    # to all liquid views. Good for registering the standard library
    def self.register_filter(mod)      
      Strainer.global_filter(mod)
    end                        
            
    # creates a new <tt>Template</tt> object from liquid source code
    def self.parse(source)
      self.new(tokenize(source))
    end                       
    
    # Uses the <tt>Liquid::TokenizationRegexp</tt> regexp to tokenize the passed source
    def self.tokenize(source)      
      return [] if source.to_s.empty?
      tokens = source.split(TokenizationRegexp)

      # removes the rogue empty element at the beginning of the array
      tokens.shift if tokens[0] and tokens[0].empty? 

      tokens
    end        

    # creates a new <tt>Template</tt> from an array of tokens. Use <tt>Template.parse</tt> instead
    def initialize(tokens = [])
      @root = Document.new(tokens)
    end
    
    # Render takes a hash with local variables.
    #
    # if you use the same filters over and over again consider registering them globally 
    # with <tt>Template.register_filter</tt>
    # 
    # Following options can be passed:
    #  
    #  * <tt>filters</tt> : array with local filters
    #  * <tt>registers</tt> : hash with register variables. Those can be accessed from 
    #    filters and tags and might be useful to integrate liquid more with its host application  
    #
    def render(assigns = {}, options = nil)
      options = { :filters => options } unless options.is_a?(Hash)
      context = Context.new(assigns, options[:registers])
      
      # Apply all filters 
      [options[:filters]].flatten.each do |filter|         
        context.add_filters(filter) 
      end
            
      # render the nodelist.
      # for performance reasons we get a array back here. to_s will make a string out of it
      @root.render(context).to_s
    end
  end  
end
