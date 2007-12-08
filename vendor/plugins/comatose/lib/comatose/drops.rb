module Comatose
  # Wrapper around a Liquid::Drop
  class ComatoseDrop < Liquid::Drop
    private :initialize
    
    def before_method(method)
      self.send(method.to_sym)
    rescue
      ComatoseController.logger.debug "Error calling #{method}: #{$!}"
      raise $!
    end
  
    class << self
      # Define a new ComatoseDrop by name
      def define( name, &block )
        d = ComatoseDrop.new
        d.instance_eval(&block)
        Comatose.registered_drops[name] = d
      rescue
        ComatoseController.logger.debug "Drop '#{name}' was not included: #{$!}"
      end
    end
  end

  # Comatose Module...
  class << self

    # Returns/initializes a hash for storing ComatoseDrops
    def registered_drops
      @registered_drops ||= {}
    end
  
    # Simple wrapper around the ProcessingContext.define method
    # I think Comatose.define_drop is probably simpler to remember too
    def define_drop(name, &block)
      ComatoseDrop.define(name, &block)
    end
    
    # Registers a 'filter' for Liquid use
    def register_filter(module_name)
      Liquid::Template.register_filter(module_name)
    end
  
  end
end


#
# Some Default Filters/Drops
#

module IncludeFilter
  def include(input)
    page = Comatose::Page.find_by_path(input)
    params = @context['params']
    # TODO: Add more of the context into the included page's context...
    page.to_html( { 'params' => params  } )
  rescue
    "Page at <tt>#{input}</tt> could not be found. <pre>#{$!}</pre>"
  end
end

Comatose.register_filter IncludeFilter


module TimeagoFilter
  class Helpers
    extend ActionView::Helpers::DateHelper
  end
  
  def time_ago(input)
    TimeagoFilter::Helpers.distance_of_time_in_words_to_now( input, true )
  rescue
    #puts "Oops! -- #{$!}"
    input
  end
end

Comatose.register_filter TimeagoFilter