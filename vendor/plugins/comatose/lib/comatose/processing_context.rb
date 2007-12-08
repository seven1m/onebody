# This is the rendering context object you have access to in text processing...
module Comatose
  class ProcessingContext
    @@supported_methods = %w(page include)

    def initialize( page, locals={} )
      @locals = locals.stringify_keys if locals.respond_to? :stringify_keys
      @page = Comatose::PageWrapper.new(page, @locals)
    end
  
    def page
      @page
    end
  
    def include(path, locals={})
      begin
        page = Comatose::Page.find_by_path(path)
        page.to_html( @locals.merge(locals) )
      rescue
        "<p>Page at <tt>#{path}</tt> could not be found.</p>"
      end
    end
  
    def find_by_path(path)
      begin
        page = Comatose::Page.find_by_path(path)
        Comatose::PageWrapper.new(page, @locals)
      rescue
        "<p>Page at <tt>#{path}</tt> could not be found.</p>"
      end
    end
  
    def [](key)
      if key.to_s.downcase == 'page'
        @page
      elsif @locals.has_key? key
        @locals[key]
      elsif Comatose.registered_drops.has_key? key
        Comatose.registered_drops[key]
      end
    end
  
    def has_key?(key)
      @@supported_methods.include?(key) or @locals.has_key?(key) or Comatose.registered_drops.has_key?(key)
    end

    def to_liquid
      self
    end
  
    def get_binding
      binding
    end

    def method_missing(method_id, *args)
      method_name = method_id.to_s
      if @locals.has_key? method_name
        @locals[method_name]
      elsif Comatose.registered_drops.has_key? method_name
        Comatose.registered_drops[method_name].context = self
        Comatose.registered_drops[method_name]
      else
        "<!-- ProcessingContext: Couldn't find #{method_id} -->"
      end
    end
  
  end
end



