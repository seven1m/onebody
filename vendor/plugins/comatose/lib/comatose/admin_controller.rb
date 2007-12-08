module Comatose

  # The controller for serving cms content...
  class AdminController < ActionController::Base
      
    define_option :original_template_root, nil
    define_option :plugin_layout_path, File.join( '..', '..', '..', 'vendor', 'plugins', 'comatose', 'views', 'layouts' )
  
    before_filter :handle_authorization
    before_filter :set_content_type
  
    # Shows the page tree
    def index
      @root_pages = [fetch_root_page].flatten
    end
  
    # Edit a specfic page (posts back)
    def edit
      # Clear the page cache for this page... ?
      @page = Comatose::Page.find params[:id]
      @root_pages = [fetch_root_page].flatten
      if request.post?
        @page.update_attributes(params[:page])
        @page.updated_on = Time.now
        @page.author = fetch_author_name
        if @page.save
          expire_cms_page @page
          expire_cms_fragment @page
          flash[:notice] = "Saved changes to '#{@page.title}'"
          redirect_to comatose_admin_url(:action=>'index')
        end
      end
    end
  
    # Create a new page (posts back)
    def new
      @root_pages = [fetch_root_page].flatten
      if request.post?
        @page = Comatose::Page.new params[:page]
        @page.author = fetch_author_name
        if @page.save
          flash[:notice] = "Created page '#{@page.title}'"
          redirect_to comatose_admin_url(:action=>'index')
        end
      else
        @page = Comatose::Page.new :title=>'New Page', :parent_id=>(params[:parent] || nil)
      end
    end
  
    # Saves position of child pages
    def reorder
      # If it's AJAX, do our thing and move on...
      if request.xhr?
        params["page_list_#{params[:id]}"].each_with_index { |id,idx| Comatose::Page.update(id, :position => idx) }
        expire_cms_page Comatose::Page.find(params[:id])
        render :text=>'Updated sort order', :layout=>false
      else
        @page = Comatose::Page.find params[:id]
        if params.has_key? :cmd
          @target = Comatose::Page.find params[:page]
          case params[:cmd]
            when 'up' then @target.move_higher
            when 'down' then @target.move_lower
          end
          redirect_to comatose_admin_url(:action=>'reorder', :id=>@page)
        end
      end
    end
  
    # Allows comparing between two versions of a page's content
    def versions
      @page = Comatose::Page.find params[:id]
      @version_num = (params[:version] || @page.versions.length).to_i
      @version = @page.find_version(@version_num)
    end
  
    # Reverts a page to a specific version...
    def set_version
      if request.post?
        @page = Comatose::Page.find params[:id]
        @version_num = params[:version]
        @page.revert_to!(@version_num)
      end
      redirect_to comatose_admin_url(:action=>'index')
    end
  
    # Deletes the specified page
    def delete
      @page = Comatose::Page.find params[:id]
      if request.post?
        expire_cms_pages_from_bottom @page
        expire_cms_fragments_from_bottom @page
        @page.destroy
        flash[:notice] = "Deleted page '#{@page.title}'"
        redirect_to comatose_admin_url(:action=>'index')
      end
    end

    # Returns a preview of the page content...
    def preview
      begin
        page = Comatose::Page.new(params[:page])
        page.author = fetch_author_name
        if params.has_key? :version
          content = page.to_html( {'params'=>params.stringify_keys, 'version'=>params[:version]} )
        else
          content = page.to_html( {'params'=>params.stringify_keys} )
        end
      rescue SyntaxError
        content = "<p>There was an error generating the preview.</p><p><pre>#{$!.to_s.gsub(/\</, '&lt;')}</pre></p>"
      rescue
        content = "<p>There was an error generating the preview.</p><p><pre>#{$!.to_s.gsub(/\</, '&lt;')}</pre></p>"
      end
      render :text=>content, :layout => false
    end
  
    # Expires the entire page cache
    def expire_page_cache
      expire_cms_pages_from_bottom( fetch_root_page )
      expire_cms_fragments_from_bottom( fetch_root_page )
      flash[:notice] = "Page cache has been flushed"
      redirect_to comatose_admin_url(:action=>'index')
    end
  
    # Walks the page tree and generates HTML files in your /public
    # folder... It will skip pages that have a 'nocache' keyword
    # TODO: Make page cache generation work when in :plugin mode
    def generate_page_cache
      if runtime_mode == :plugin
        @errors = ["Page cache cannot be generated in plugin mode"]
      else
        @errors = generate_all_pages_html(params)
      end
      if @errors.length == 0 
        flash[:notice] = "Pages Cached Successfully"
      else
        flash[:notice] = "Pages Cache Error(s): #{@errors.join(', ')}"
        flash[:cache_errors] = @errors 
      end
      redirect_to comatose_admin_url(:action=>'index')
    end

  
  protected

    def handle_authorization
      if Comatose.config.admin_authorization.is_a? Proc
        instance_eval &Comatose.config.admin_authorization
      elsif Comatose.config.admin_authorization.is_a? Symbol
        send(Comatose.config.admin_authorization)
      elsif defined? authorize
        authorize
      else
        true
      end
    end

    def fetch_author_name
      if Comatose.config.admin_get_author.is_a? Proc
        instance_eval &Comatose.config.admin_get_author
      elsif Comatose.config.admin_get_author.is_a? Symbol
        send(Comatose.config.admin_get_author)
      elsif defined? get_author
        get_author
      end
    end
  
    # Can be overridden -- return your root comtase page
    def fetch_root_page
      if Comatose.config.admin_get_root_page.is_a? Proc
        instance_eval &Comatose.config.admin_get_root_page
      elsif Comatose.config.admin_get_root_page.is_a? Symbol
        send(Comatose.config.admin_get_root_page)
      elsif defined? get_root_page
        get_root_page
      end      
    end
  
    # Sets the HTTP content-type header based on what's configured 
    # in Comatose.config.content_type
    def set_content_type
      response.headers["Content-Type"] = "text/html; charset=#{Comatose.config.content_type}" unless Comatose.config.content_type.nil?
    end
  
    # Calls generate_page_html for each mount point..
    def generate_all_pages_html(params={})
      @errors = []
      @been_cached = []
      Comatose.mount_points.each do |root_info|
        Comatose::Page.active_mount_info = root_info
        generate_page_html(Comatose::Page.find_by_path( root_info[:index] ), root_info, params)
      end
      @errors
    end
  
    # Accepts a Comatose Page and a root_info object to generate
    # the page as a static HTML page -- using the layout that was
    # defined on the mount point
    def generate_page_html(page, root_info, params={})
      @been_cached ||= []
      unless page.has_keyword? :nocache or @been_cached.include? page.id
        uri = page.uri
        uri = "#{uri}/index".split('/').flatten.join('/') if page.full_path == root_info[:index]
        @page = Comatose::PageWrapper.new(page)
        begin
          page_layout = get_page_layout(root_info)
          #puts "mode = #{runtime_mode}, layout = #{page_layout}, template_root = #{template_root}, original_template_root = #{original_template_root}"
          html = render_to_string( :text=>page.to_html({'params'=>params.stringify_keys}), :layout=>page_layout )
          cache_page( html, uri )
        rescue
          logger.error "Comatose CMS Page Cache Exception: #{$!}"
          @errors << "(#{page}/#{page.slug}) - #{$!}"
        end
        @been_cached << page.id
        # recurse...
        page.children.each do |child|
          generate_page_html(child, root_info)
        end
      end
    end
    
    # Calls the class methods of the same name...
    def expire_cms_page(page)
      self.class.expire_cms_page(page)
    end
    def expire_cms_pages_from_bottom(page)
      self.class.expire_cms_pages_from_bottom(page)
    end
    
  
    # expire the page from the fragment cache
    def expire_cms_fragment(page)
      key = page.full_path.gsub(/\//, '+')
      expire_fragment(key)
    end
  
    # expire pages starting at a specific node
    def expire_cms_fragments_from_bottom(page)
      pages = page.is_a?(Array) ? page : [page] 
      pages.each do |page|
        page.children.each {|c| expire_cms_fragments_from_bottom( c ) } if !page.children.empty?
        expire_cms_fragment( page )
      end
    end
  
    # Class Methods...
    class << self

      # Walks all the way down, and back up the tree -- the allows the expire_cms_page
      # to delete empty directories better
      def expire_cms_pages_from_bottom(page)
        pages = page.is_a?(Array) ? page : [page] 
        pages.each do |page|
          page.children.each {|c| expire_cms_pages_from_bottom( c ) } if !page.children.empty?
          expire_cms_page( page )
        end
      end

      # Expire the page from all the mount points...
      def expire_cms_page(page)
        Comatose.mount_points.each do |path_info|
          Comatose::Page.active_mount_info = path_info
          expire_page(page.uri)
          # If the page is the index page for the root, expire it too
          if path_info[:root] == page.uri
            expire_page("#{path_info[:root]}/index")
          end
          begin # I'm not sure this matters too much -- but it keeps things clean
            dir_path = File.join(RAILS_ROOT, 'public', page.uri[1..-1])
            Dir.delete( dir_path ) if FileTest.directory?( dir_path ) and !page.parent.nil?
          rescue
            # It probably isn't empty -- just as well we leave it be
            #STDERR.puts " - Couldn't delete dir #{dir_path} -> #{$!}"
          end 
        end
      end

      # Returns a path to plugin layout, if it's unspecified, otherwise
      # a path to an application layout...
      def get_page_layout(params)
        if params[:layout] == 'comatose_content'
          File.join(plugin_layout_path, params[:layout])
        else
          params[:layout]
        end
      end
    
      def configure_template_root
        if self.runtime_mode == :unknown
          if FileTest.exist? File.join(RAILS_ROOT, 'public', 'javascripts', 'comatose_admin.js')
            self.runtime_mode = :application
          else
            self.runtime_mode = :plugin
          end
        end
      end

      def runtime_mode
        @@runtime_mode ||= :unknown
      end
    
      def runtime_mode=(mode)
        admin_view_path = File.expand_path(File.join( File.dirname(__FILE__), '..', '..', 'views'))
        if self.respond_to?(:template_root)
          case mode
          when :plugin
            self.original_template_root = self.template_root
            self.template_root = admin_view_path
          when :application
            self.template_root = self.original_template_root if self.original_template_root
          end
        else
          ActionController::Base.append_view_path(admin_view_path) unless ActionController::Base.view_paths.include?(admin_view_path)
        end
        @@runtime_mode = mode
      end

    end
    
    # Check to see if we are in 'embedded' mode, or are being 'customized'
    #  embedded   = runtime_mode of :plugin
    #  customized = runtime_mode of :application
    configure_template_root
    
    #
    # Include any modules...
    Comatose.config.admin_includes.each do |mod|
      if mod.is_a? String
        include mod.constantize
      elsif mod.is_a? Symbol
        include mod.to_s.classify.constantize
      else
        include mod
      end
    end

    # Include any helpers...
    Comatose.config.admin_helpers.each do |mod|
      if mod.is_a? String
        helper mod.constantize
      elsif mod.is_a? Symbol
        helper mod.to_s.classify.constantize
      else
        helper mod
      end
    end


  end

end

