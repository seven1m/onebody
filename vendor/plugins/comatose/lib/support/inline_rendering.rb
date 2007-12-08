# Extends the view to support rendering inline comatose pages...
ActionView::Base.class_eval do
  alias_method :render_otherwise, :render
  
  def render(options = {}, old_local_assigns = {}, &block) #:nodoc:
    if options.is_a?(Hash) && page_name = options.delete(:comatose)
      render_comatose(page_name, options[:params] || options)
    else
      render_otherwise(options, old_local_assigns, &block)
    end
  end
  
  def render_comatose(page_path, params = {})
    params = {
      :silent => false,
      :use_cache => true,
      :locals => {}
    }.merge(params)
    if params[:use_cache] and params[:locals].empty?
      render_cached_comatose_page(page_path, params)
    else
      render_comatose_page(page_path, params)
    end
  end
  
protected
  
  def render_cached_comatose_page(page_path, params)
    key = page_path.gsub(/\//, '+')
    unless html = controller.read_fragment(key)
      html = render_comatose_page( page_path, params )
      controller.write_fragment(key, html) unless Comatose.config.disable_caching
    end
    html
  end
  
  def render_comatose_page(page_path, params)
    if page = Comatose::Page.find_by_path(page_path)
      # Add the request params to the context...
      params[:locals]['params'] = controller.params
      html = page.to_html( params[:locals] )
    else
      html = params[:silent] ? '' : "<p><tt>#{page_path}</tt> not found</p>"
    end
  end
  
end

