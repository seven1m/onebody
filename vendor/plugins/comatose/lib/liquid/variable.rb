module Liquid
  
  # Hols variables. Variables are only loaded "just in time"
  # they are not evaluated as part of the render stage
  class Variable    
    attr_accessor :filters, :name
    
    def initialize(markup)
      @markup = markup                            
      @name = markup.match(/\s*(#{QuotedFragment})/)[1]
      if markup.match(/#{FilterSperator}\s*(.*)/)
        filters = Regexp.last_match(1).split(/#{FilterSperator}/)
        
        @filters = filters.collect do |f|          
          filtername = f.match(/\s*(\w+)/)[1]
          filterargs = f.scan(/(?:#{FilterArgumentSeparator}|#{ArgumentSeparator})\s*(#{QuotedFragment})/).flatten            
          [filtername.to_sym, filterargs]
        end
      else
        @filters = []
      end
    end                        

    def render(context)      
      output = context[@name]
      @filters.inject(output) do |output, filter|
        filterargs = filter[1].to_a.collect do |a|
         context[a]
        end
        begin
          output = context.invoke(filter[0], output, *filterargs)
        rescue FilterNotFound
          raise FilterNotFound, "Error - filter '#{filter[0]}' in '#{@markup.strip}' could not be found."
        end
      end  
      output
    end
  end
end