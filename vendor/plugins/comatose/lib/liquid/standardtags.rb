module Liquid 
  
  class Assign < Tag
    Syntax = /(\w+)\s*=\s*(#{AllowedVariableCharacters}+)/   
    
    def initialize(markup, tokens)
      if markup =~ Syntax
        @to = $1
        @from = $2
      else
        raise SyntaxError.new("Syntax Error in 'assign' - Valid syntax: assign [var] = [source]")
      end
    end
    
    def render(context)
       context[@to] = context[@from]
       ''       
    end 
    
  end  
  
  class Capture < Block
    Syntax = /(\w+)/

    def initialize(markup, tokens)
      if markup =~ Syntax
        @to = $1
        super 
      else
        raise SyntaxError.new("Syntax Error in 'capture' - Valid syntax: capture [var]")
      end
    end

    def render(context)
      output = super
      context[@to] = output.to_s
      ''
    end
  end
 
  class Cycle < Tag
    SimpleSyntax = /#{QuotedFragment}/        
    NamedSyntax = /(#{QuotedFragment})\s*\:\s*(.*)/
    
    def initialize(markup, tokens)
      case markup
      when NamedSyntax
      	@variables = variables_from_string($2)
      	@name = $1
      when SimpleSyntax
        @variables = variables_from_string(markup)
      	@name = "'#{@variables.to_s}'"
      else
        raise SyntaxError.new("Syntax Error in 'cycle' - Valid syntax: cycle [name :] var [, var2, var3 ...]")
      end
      
    end    
    
    def render(context)
      context.registers[:cycle] ||= Hash.new(0)
      
      context.stack do
        key = context[@name]	
        iteration = context.registers[:cycle][key]
        result = context[@variables[iteration]]
        iteration += 1    
        iteration   = 0  if iteration >= @variables.size 
        context.registers[:cycle][key] = iteration
        result 
      end
    end
    
    private
    
    def variables_from_string(markup)
      markup.split(',').collect do |var|
    	  var =~ /\s*(#{QuotedFragment})\s*/
    	  $1 ? $1 : nil
    	end.compact
    end
    
  end
  
  class Comment < Block                                             
    def render(context)
      ''
    end    
  end

  class For < Block                                             
    Syntax = /(\w+)\s+in\s+(#{AllowedVariableCharacters}+)/   
    
    def initialize(markup, tokens)
      super

      if markup =~ Syntax
        @variable_name = $1
        @collection_name = $2
        @name = "#{$1}-#{$2}"
        @attributes = {}
        markup.scan(TagAttributes) do |key, value|
          @attributes[key] = value
        end        
      else
        raise SyntaxError.new("Syntax Error in 'for loop' - Valid syntax: for [item] in [collection]")
      end
    end
    
    def render(context)        
      context.registers[:for] ||= Hash.new(0)
      
      collection = context[@collection_name]
      
      return '' if collection.nil? or collection.empty?
      
      range = (0..collection.length)
      
      if @attributes['limit'] or @attributes['offset']
        
        
        offset = 0
        if @attributes['offset'] == 'continue'
          offset = context.registers[:for][@name] 
        else          
          offset = context[@attributes['offset']] || 0
        end
        
        limit  = context[@attributes['limit']]

        range_end = limit ? offset + limit : collection.length
        
        range = (offset..range_end-1)
        
        # Save the range end in the registers so that future calls to 
        # offset:continue have something to pick up
        context.registers[:for][@name] = range_end
      end
              
      result = []
      segment = collection[range]
      return '' if segment.nil?        

      context.stack do 
        length = segment.length
        
        segment.each_with_index do |item, index|
          context[@variable_name] = item
          context['forloop'] = {
            'name'    => @name,
            'length'  => length,
            'index'   => index + 1, 
            'index0'  => index, 
            'rindex'  => length - index,
            'rindex0' => length - index -1,
            'first'   => (index == 0),
            'last'    => (index == length - 1) }
          
          result << render_all(@nodelist, context)
        end
      end
      
      # Store position of last element we rendered. This allows us to do 
      
      result 
    end           
  end
  
   
  class DecisionBlock < Block
    def equal_variables(right, left)
      if left.is_a?(Symbol)
        if right.respond_to?(left.to_s)
          return right.send(left.to_s) 
        else
          raise ArgumentError.new("Error in tag '#{name}' - Cannot call method #{left} on type #{right.class}}")
        end
      end

      if right.is_a?(Symbol)
        if left.respond_to?(right.to_s)
          return left.send(right.to_s) 
        else
          raise ArgumentError.new("Error in tag '#{name}' - Cannot call method #{right} on type #{left.class}}")
        end
      end

      left == right      
    end    

    def interpret_condition(left, right, op, context)   

      # If the operator is empty this means that the decision statement is just 
      # a single variable. We can just poll this variable from the context and 
      # return this as the result.
      return context[left] if op == nil      
      
      left, right = context[left], context[right]
      
      operation = case op
      when '==' then return equal_variables(left, right)
      when '!=' then return !equal_variables(left, right)
      when '>'  then :>
      when '<'  then :<
      when '>=' then :>=
      when '<=' then :<=
      else
        raise ArgumentError.new("Error in tag '#{name}' - Unknown operator #{op}")        
      end
      
      if left.respond_to?(operation) and right.respond_to?(operation)
        left.send(operation, right)      
      else
        nil
      end
    end    
  end
  
  
  class Case < DecisionBlock
    Syntax     = /(#{QuotedFragment})/
    WhenSyntax = /(#{QuotedFragment})/

    def initialize(markup, tokens)
      @nodelists = []
      @else_nodelist = []
      
      super

      if markup =~ Syntax
        @left = $1
      else
        raise SyntaxError.new("Syntax Error in tag 'case' - Valid syntax: case [condition]")
      end
    end
    
    def end_tag
      push_nodelist
    end

    def unknown_tag(tag, params, tokens)
      case tag 
      when 'when'
        if params =~ WhenSyntax          
          push_nodelist
          @right = $1
          @nodelist = [] 
        else
          raise SyntaxError.new("Syntax Error in tag 'case' - Valid when condition: when [condition] ")
        end
      when 'else'
        push_nodelist
        @right = nil
        @else_nodelist = @nodelist = [] 
      else
        super
      end
    end
    
    def push_nodelist
      if @right
        # only push the nodelist if there was actually a when condition stated before. 
        # we discard all tokens between the case and the first when condition this way...
        @nodelists << [@right, @nodelist] 
      end
    end

    def render(context)
      output = []
      run_else_block = true
      
      @nodelists.each do |right, nodelist|
        if equal_variables(context[@left], context[right])
          run_else_block = false
          context.stack do          
            output += render_all(nodelist, context)
          end
        end
      end            
      
      if run_else_block
        context.stack do          
          output += render_all(@else_nodelist, context)       
        end
      end
      
      output.to_s
    end    
  end  
  
  class If < DecisionBlock
    Syntax = /(#{QuotedFragment})\s*([=!<>]+)?\s*(#{QuotedFragment})?/
    
    def initialize(markup, tokens)
      @nodelist_true = @nodelist = []
      @nodelist_false = []

      super
                       
      if markup =~ Syntax
        @left = $1
        @operator = $2 
        @right = $3
      else
        raise SyntaxError.new("Syntax Error in tag 'if' - Valid syntax: if [condition]")
      end
      
    end
    
    def unknown_tag(tag, params, tokens)
      if tag == 'else'
        @nodelist = @nodelist_false = []
      else
        super
      end
    end
    
    def render(context)
      context.stack do       
        if interpret_condition(@left, @right, @operator, context)
          render_all(@nodelist_true, context)
        else
          render_all(@nodelist_false, context)
        end
      end
    end
  end
  
  class Unless < If
    def render(context)
      context.stack do       
        if interpret_condition(@left, @right, @operator, context)
          render_all(@nodelist_false, context)
        else
          render_all(@nodelist_true, context)
        end
      end
    end
  end
  
  class Include < Tag
    Syntax = /("[^"]+"|'[^']+')(\s+(with|for)\s+(#{QuotedFragment}+))?/
    
    def initialize(markup, tokens)
      if markup =~ Syntax
        @template_name = $1[1...-1]
        if $2
          @collection = ($3 == "for")
          @variable = $4
        end
        @attributes = {}
        markup.scan(TagAttributes) do |key, value|
          @attributes[key] = value
        end
      else
        raise SyntaxError.new("Error in tag 'include' - Valid syntax: include '[template]' (with|for) [object|collection]")
      end

      super
    end
    
    def parse(tokens)      
      source = Liquid::Template.file_system.read_template_file(@template_name)
      tokens = Liquid::Template.tokenize(source)
      @document = Document.new(tokens)
    end
    
    def render(context)
      result = ''
      variable = context[@variable]
      context.stack do
        @attributes.each do |key, value|
          context[key] = context[value]
        end
        if @collection 
          variable.each do |item|
            context[@template_name] = item
            result << @document.render(context).to_s
          end
        else 
          if @variable          
            context[@template_name] = variable
          end
          result << @document.render(context).to_s
        end
      end
      result
    end
  end
  
  Template.register_tag('assign', Assign)
  Template.register_tag('capture', Capture)
  Template.register_tag('comment', Comment)
  Template.register_tag('for', For)
  Template.register_tag('if', If)
  Template.register_tag('unless', Unless)
  Template.register_tag('case', Case)
  Template.register_tag('cycle', Cycle)
  Template.register_tag('include', Include)  
end 
